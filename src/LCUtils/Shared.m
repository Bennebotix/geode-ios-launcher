#import "LCUtils.h"
#import "Shared.h"
#import "src/Utils.h"
#import <UIKit/UIKit.h>

@implementation LCPath

+ (NSURL*)docPath {
	return [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
}

+ (NSURL*)bundlePath {
	if (![Utils isSandboxed]) {
		NSString* bundlePath = [Utils getGDBundlePath];
		if (bundlePath) {
			return [NSURL URLWithString:bundlePath];
		}
	}
	return [[self docPath] URLByAppendingPathComponent:@"Applications"];
}

+ (NSURL*)dataPath {
	__block NSURL* ans;
	if ([[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
		[Utils accessHelper:NO completionHandler:^(NSURL* url, BOOL success, NSString* error) {
			if ((!success && [error isEqualToString:@"Stale"]) || success) {
				ans = url;
			}
		}];
	} else {
		ans = [[self docPath] URLByAppendingPathComponent:@"Data/Application/GeometryDash/Documents"];
	}
	if (ans == nil)
		ans = [[self docPath] URLByAppendingPathComponent:@"Data/Application/GeometryDash/Documents"]; // since otherwise itll crash if the bookmark no existe...
	return ans;
}

+ (NSURL*)appGroupPath {
	return [[self docPath] URLByAppendingPathComponent:@"Data/AppGroup"];
}

+ (NSURL*)tweakPath {
	return [[self docPath] URLByAppendingPathComponent:@"Tweaks"];
}

+ (NSURL*)realLCDocPath {
	return [[self docPath] URLByAppendingPathComponent:@"../../../../"];
}

+ (NSURL*)lcGroupDocPath {
	NSFileManager* fm = [NSFileManager defaultManager];
	NSURL* appGroupUrl = [fm containerURLForSecurityApplicationGroupIdentifier:@"group.com.SideStore.SideStore"];
	if (appGroupUrl) {
		return [appGroupUrl URLByAppendingPathComponent:@"Geode"];
	} else {
		return [self docPath];
	}
}

+ (NSURL*)lcGroupBundlePath {
	return [[self lcGroupDocPath] URLByAppendingPathComponent:@"Applications"];
}

+ (NSURL*)lcGroupDataPath {
	return [[self lcGroupDocPath] URLByAppendingPathComponent:@"Data/Application"];
}

+ (NSURL*)lcGroupAppGroupPath {
	return [[self lcGroupDocPath] URLByAppendingPathComponent:@"Data/AppGroup"];
}

+ (NSURL*)lcGroupTweakPath {
	return [[self lcGroupDocPath] URLByAppendingPathComponent:@"Tweaks"];
}

+ (void)ensureAppGroupPaths:(NSError**)error {
	NSFileManager* fm = [NSFileManager defaultManager];
	/*NSArray *paths = @[
		[self lcGroupBundlePath],
		[self lcGroupDataPath],
		[self lcGroupTweakPath]
	];*/
	NSArray* paths = @[ [self bundlePath], [self dataPath], [self tweakPath] ];

	for (NSURL* url in paths) {
		NSString* path = url.path;
		if (![fm fileExistsAtPath:path]) {
			[fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error];
			if (*error) {
				return;
			}
		}
	}
}

@end

@implementation SharedModel

- (BOOL)isPhone {
	return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
}

- (instancetype)init {
	if (self = [super init])
		return self;
	return self;
}

@end
