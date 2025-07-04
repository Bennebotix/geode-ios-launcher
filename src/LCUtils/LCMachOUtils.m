@import Darwin;
@import Foundation;
@import MachO;
#import "../components/LogUtils.h"
#import "LCUtils.h"
// #import <Foundation/Foundation.h>
// #import <mach-o/dyld.h>
// #import <mach-o/loader.h>

static uint32_t rnd32(uint32_t v, uint32_t r) {
	r--;
	return (v + r) & ~r;
}

static void insertDylibCommand(uint32_t cmd, const char* path, struct mach_header_64* header) {
	const char* name = cmd == LC_ID_DYLIB ? basename((char*)path) : path;
	struct dylib_command* dylib = (struct dylib_command*)(sizeof(struct mach_header_64) + (void*)header + header->sizeofcmds);
	dylib->cmd = cmd;
	dylib->cmdsize = sizeof(struct dylib_command) + rnd32((uint32_t)strlen(name) + 1, 8);
	dylib->dylib.name.offset = sizeof(struct dylib_command);
	dylib->dylib.compatibility_version = 0x10000;
	dylib->dylib.current_version = 0x10000;
	dylib->dylib.timestamp = 2;
	strncpy((void*)dylib + dylib->dylib.name.offset, name, strlen(name));
	header->ncmds++;
	header->sizeofcmds += dylib->cmdsize;
}

void noopOverwrite(struct load_command* command) {
	uint32_t old_size = command->cmdsize;
	memset(command, 0, old_size);
	command->cmd = 0x12345678; // dont question it lol, apple will most likely not have a command with this so itll just ignore it... hopefully
	command->cmdsize = old_size;
}

static void insertRPathCommand(const char* path, struct mach_header_64* header) {
	struct rpath_command* rpath = (struct rpath_command*)(sizeof(struct mach_header_64) + (void*)header + header->sizeofcmds);
	rpath->cmd = LC_RPATH;
	rpath->cmdsize = sizeof(struct rpath_command) + rnd32((uint32_t)strlen(path) + 1, 8);
	rpath->path.offset = sizeof(struct rpath_command);
	strncpy((void*)rpath + rpath->path.offset, path, strlen(path));
	header->ncmds++;
	header->sizeofcmds += rpath->cmdsize;
}

void LCPatchAddRPath(const char* path, struct mach_header_64* header) {
	insertRPathCommand("@executable_path/../../Tweaks", header);
	insertRPathCommand("@loader_path", header);
}

void LCPatchExecSlice(const char* path, struct mach_header_64* header, bool withGeode) {
	uint8_t* imageHeaderPtr = (uint8_t*)header + sizeof(struct mach_header_64);

	// Literally convert an executable to a dylib
	if (header->magic == MH_MAGIC_64) {
		// assert(header->flags & MH_PIE);
		if (withGeode) { // how about no, we want it as executable again!
			header->filetype = MH_EXECUTE;
			header->flags |= MH_PIE;
			header->flags &= ~MH_NO_REEXPORTED_DYLIBS;
		} else {
			header->filetype = MH_DYLIB;
			header->flags |= MH_NO_REEXPORTED_DYLIBS;
			header->flags &= ~MH_PIE;
		}
	}

	BOOL hasDylibCommand = NO, hasLoaderCommand = NO;
	const char* tweakLoaderPath = "@loader_path/../../Tweaks/TweakLoader.dylib";
	// const char* geodeLoaderPath = "@executable_path/Geode.ios.dylib";
	const char* geodeLoaderPath = "@executable_path/EnterpriseLoader.dylib";
	// const char* geodeLoaderPath = "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation";
	struct load_command* command = (struct load_command*)imageHeaderPtr;
	struct load_command* lcIDcmd;
	struct dylib_command* lcLOADcmd;
	for (int i = 0; i < header->ncmds; i++) {
		if (command->cmd == LC_ID_DYLIB) {
			lcIDcmd = command;
			hasDylibCommand = YES;
		} else if (command->cmd == LC_LOAD_DYLIB) {
			struct dylib_command* dylib = (struct dylib_command*)command;
			char* dylibName = (void*)dylib + dylib->dylib.name.offset;
			if (!strncmp(dylibName, tweakLoaderPath, strlen(tweakLoaderPath))) {
				lcLOADcmd = dylib;
				hasLoaderCommand = YES;
			}
		}
		command = (struct load_command*)((void*)command + command->cmdsize);
	}
	if (withGeode) { // we're just going to decide to NO-OP the commands then i guess add the LC_LOAD_DYLIB command
		if (hasDylibCommand && hasLoaderCommand) {
			uint32_t totalSpace = lcIDcmd->cmdsize + lcLOADcmd->cmdsize;
			uint32_t newCmdSize = sizeof(struct dylib_command) + rnd32((uint32_t)strlen(geodeLoaderPath) + 1, 8);
			if (newCmdSize <= totalSpace) { // this shouldnt happen but you never know!
				memset(lcIDcmd, 0, totalSpace);
				struct dylib_command* newCmd = (struct dylib_command*)lcIDcmd;
				newCmd->cmd = LC_LOAD_DYLIB;
				newCmd->cmdsize = newCmdSize;
				newCmd->dylib.name.offset = sizeof(struct dylib_command);
				newCmd->dylib.compatibility_version = 0x10000;
				newCmd->dylib.current_version = 0x10000;
				newCmd->dylib.timestamp = 2;
				strncpy((void*)newCmd + newCmd->dylib.name.offset, geodeLoaderPath, strlen(geodeLoaderPath));

				if (totalSpace > newCmdSize) {
					struct load_command* padding = (struct load_command*)((uint8_t*)newCmd + newCmdSize);
					padding->cmd = 0; // This will be ignored
					padding->cmdsize = totalSpace - newCmdSize;
				}
				header->ncmds--;
			} else {
				noopOverwrite(lcIDcmd);
				noopOverwrite((struct load_command*)lcLOADcmd);
				insertDylibCommand(LC_LOAD_DYLIB, geodeLoaderPath, header);
				header->ncmds -= 2;
			}
		} else {
			// something must really be wrong if this were to pass
			// insertDylibCommand(LC_LOAD_DYLIB, geodeLoaderPath, header);
		}
	} else {
		if (!hasDylibCommand) {
			insertDylibCommand(LC_ID_DYLIB, path, header);
		}
		if (!hasLoaderCommand) {
			insertDylibCommand(LC_LOAD_DYLIB, tweakLoaderPath, header);
		}
	}

	// Patch __PAGEZERO to map just a single zero page, fixing "out of address space"
	struct segment_command_64* seg = (struct segment_command_64*)imageHeaderPtr;
	assert(seg->cmd == LC_SEGMENT_64);
	if (seg->vmaddr == 0) {
		assert(seg->vmsize == 0x100000000);
		seg->vmaddr = 0x100000000 - 0x4000;
		seg->vmsize = 0x4000;
	} else if (withGeode) {
		// we arent containerizing it so...
		seg->vmaddr = 0x0;
		seg->vmsize = 0x100000000;
	}
}

NSString* LCParseMachO(const char* path, bool readOnly, LCParseMachOCallback callback) {
	int fd = open(path, readOnly ? O_RDONLY : O_RDWR, (mode_t)readOnly ? 0400 : 0600);
	struct stat s;
	fstat(fd, &s);
	void* map = mmap(NULL, s.st_size, readOnly ? PROT_READ : (PROT_READ | PROT_WRITE), readOnly ? MAP_PRIVATE : MAP_SHARED, fd, 0);
	if (map == MAP_FAILED) {
		AppLog(@"LCParseMachO error: %@", [NSString stringWithFormat:@"Failed to map %s: %s", path, strerror(errno)]);
		return [NSString stringWithFormat:@"Failed to map %s: %s", path, strerror(errno)];
	}

	uint32_t magic = *(uint32_t*)map;
	if (magic == FAT_CIGAM) {
		// Find compatible slice
		struct fat_header* header = (struct fat_header*)map;
		struct fat_arch* arch = (struct fat_arch*)(map + sizeof(struct fat_header));
		for (int i = 0; i < OSSwapInt32(header->nfat_arch); i++) {
			if (OSSwapInt32(arch->cputype) == CPU_TYPE_ARM64) {
				callback(path, (struct mach_header_64*)(map + OSSwapInt32(arch->offset)), fd, map);
			}
			arch = (struct fat_arch*)((void*)arch + sizeof(struct fat_arch));
		}
	} else if (magic == MH_MAGIC_64) {
		callback(path, (struct mach_header_64*)map, fd, map);
	} else if (magic == MH_MAGIC) {
		AppLog(@"LCParseMachO error: 32-bit app is not supported");
		return @"32-bit app is not supported";
	} else {
		AppLog(@"LCParseMachO error: Not a Mach-O file");
		return @"Not a Mach-O file";
	}

	msync(map, s.st_size, MS_SYNC);
	munmap(map, s.st_size);
	close(fd);
	return nil;
}

void LCChangeExecUUID(struct mach_header_64* header) {
	uint8_t* imageHeaderPtr = (uint8_t*)header + sizeof(struct mach_header_64);
	struct load_command* command = (struct load_command*)imageHeaderPtr;
	for (int i = 0; i < header->ncmds; i++) {
		if (command->cmd == LC_UUID) {
			struct uuid_command* uuidCmd = (struct uuid_command*)command;
			// let's add the first byte by 1
			uuidCmd->uuid[0] += 1;
			break;
		}
		command = (struct load_command*)((void*)command + command->cmdsize);
	}
}

struct code_signature_command {
	uint32_t cmd;
	uint32_t cmdsize;
	uint32_t dataoff;
	uint32_t datasize;
};

// from zsign
struct ui_CS_BlobIndex {
	uint32_t type;	 /* type of entry */
	uint32_t offset; /* offset of entry */
};

struct ui_CS_SuperBlob {
	uint32_t magic;	 /* magic number */
	uint32_t length; /* total length of SuperBlob */
	uint32_t count;	 /* number of index entries following */
					 // CS_BlobIndex index[];            /* (count) entries */
					 /* followed by Blobs in no particular order as indicated by offsets in index */
};

struct ui_CS_blob {
	uint32_t magic;
	uint32_t length;
};

struct code_signature_command* findSignatureCommand(struct mach_header_64* header) {
	uint8_t* imageHeaderPtr = (uint8_t*)header + sizeof(struct mach_header_64);
	struct load_command* command = (struct load_command*)imageHeaderPtr;
	struct code_signature_command* codeSignCommand = 0;
	for (int i = 0; i < header->ncmds; i++) {
		if (command->cmd == LC_CODE_SIGNATURE) {
			codeSignCommand = (struct code_signature_command*)command;
			break;
		}
		command = (struct load_command*)((void*)command + command->cmdsize);
	}
	return codeSignCommand;
}

NSString* getLCEntitlementXML(void) {
	struct mach_header_64* header = dlsym(RTLD_MAIN_ONLY, MH_EXECUTE_SYM);
	struct code_signature_command* codeSignCommand = findSignatureCommand(header);

	if (!codeSignCommand) {
		return @"Unable to find LC_CODE_SIGNATURE command.";
	}
	struct ui_CS_SuperBlob* blob = (void*)header + codeSignCommand->dataoff;
	if (blob->magic != OSSwapInt32(0xfade0cc0)) {
		return [NSString stringWithFormat:@"CodeSign blob magic mismatch %8x.", blob->magic];
	}
	struct ui_CS_BlobIndex* entitlementBlobIndex = 0;
	struct ui_CS_BlobIndex* nowIndex = (void*)blob + sizeof(struct ui_CS_SuperBlob);
	for (int i = 0; i < OSSwapInt32(blob->count); i++) {
		if (OSSwapInt32(nowIndex->type) == 5) {
			entitlementBlobIndex = nowIndex;
			break;
		}
		nowIndex = (void*)nowIndex + sizeof(struct ui_CS_BlobIndex);
	}
	if (entitlementBlobIndex == 0) {
		return @"[LC] entitlement blob index not found.";
	}
	struct ui_CS_blob* entitlementBlob = (void*)blob + OSSwapInt32(entitlementBlobIndex->offset);
	if (entitlementBlob->magic != OSSwapInt32(0xfade7171)) {
		return [NSString stringWithFormat:@"EntitlementBlob magic mismatch %8x.", blob->magic];
	};
	int32_t xmlLength = OSSwapInt32(entitlementBlob->length) - sizeof(struct ui_CS_blob);
	void* xmlPtr = (void*)entitlementBlob + sizeof(struct ui_CS_blob);

	// entitlement xml in executable don't have \0 so we have to copy it first
	char* xmlString = malloc(xmlLength + 1);
	memcpy(xmlString, xmlPtr, xmlLength);
	xmlString[xmlLength] = 0;

	NSString* ans = [NSString stringWithUTF8String:xmlString];
	free(xmlString);
	return ans;
}

bool checkCodeSignature(const char* path) {
	__block bool checked = false;
	__block bool ans = false;
	LCParseMachO(path, true, ^(const char* path, struct mach_header_64* header, int fd, void* filePtr) {
		if (checked || header->cputype != CPU_TYPE_ARM64) {
			return;
		}
		checked = true;
		struct code_signature_command* codeSignatureCommand = findSignatureCommand(header);
		if (!codeSignatureCommand) {
			AppLog(@"Couldn't find sig command for header");
			return;
		}
		off_t sliceOffset = (void*)header - filePtr;
		fsignatures_t siginfo;
		siginfo.fs_file_start = sliceOffset;
		siginfo.fs_blob_start = (void*)(long)(codeSignatureCommand->dataoff);
		siginfo.fs_blob_size = codeSignatureCommand->datasize;
		int addFileSigsReault = fcntl(fd, F_ADDFILESIGS_RETURN, &siginfo);
		if (addFileSigsReault == -1) {
			AppLog(@"F_ADDFILESIGS_RETURN failed: %s (%d). If you are running this in LiveContainer, please enable \"Fix File Picker & Local Notification\"", strerror(errno),
				   errno);
			ans = false;
			return;
		}
		fchecklv_t checkInfo;
		char messageBuffer[512];
		messageBuffer[0] = '\0';
		checkInfo.lv_error_message_size = sizeof(messageBuffer);
		checkInfo.lv_error_message = messageBuffer;
		checkInfo.lv_file_start = sliceOffset;
		int checkLVresult = fcntl(fd, F_CHECK_LV, &checkInfo);

		if (checkLVresult == 0) {
			ans = true;
			return;
		} else {
			AppLog(@"F_CHECK_LV failed: %s (%d)", strerror(errno), errno);
			ans = false;
			return;
		}
	});
	return ans;
}
