#import "AppDelegate.h"
#import "GeodeInstaller.h"
#import "IconView.h"
#import "LogsView.h"
#import "SettingsVC.h"
#import "VerifyInstall.h"
#import "components/FileBrowserVC.h"
#import "components/LogUtils.h"
#import "src/JITLessVC.h"
#import "src/LCUtils/LCUtils.h"
#import "src/LCUtils/Shared.h"
#import "src/Theming.h"
#import "src/Utils.h"
#import "src/components/NSUDBrowserVC.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <dlfcn.h>
#include <spawn.h>

#import "Patcher.h"

@interface SettingsVC () <UIDocumentPickerDelegate>
@property(nonatomic, strong) NSArray* creditsArray;
@property(nonatomic, assign) BOOL isImportCert;
@property(nonatomic, assign) BOOL isImportIPA;
@end

@implementation SettingsVC
- (void)viewDidLoad {
	[super viewDidLoad];
	[self setTitle:@"Settings"];
	self.creditsArray = @[
		@{ @"name" : @"rooot", @"url" : @"https://github.com/RoootTheFox" },
		@{ @"name" : @"dankmeme01", @"url" : @"https://github.com/dankmeme01" },
		@{ @"name" : @"Firee", @"url" : @"https://github.com/FireMario211" },
		@{ @"name" : @"ninXout", @"url" : @"https://github.com/ninXout" },
		@{ @"name" : @"alk", @"url" : @"https://github.com/altalk23" },
		@{ @"name" : @"Duy Tran Khanh", @"url" : @"https://github.com/khanhduytran0" },
		@{ @"name" : @"camila314", @"url" : @"https://github.com/camila314" },
		@{ @"name" : @"TheSillyDoggo", @"url" : @"https://github.com/TheSillyDoggo" },
		@{ @"name" : @"Nathan", @"url" : @"https://github.com/verygenericname" },
		@{ @"name" : @"LimeGradient", @"url" : @"https://github.com/LimeGradient" },
		@{ @"name" : @"km7dev", @"url" : @"https://github.com/Kingminer7" },
		@{ @"name" : @"Anh", @"url" : @"https://github.com/AnhNguyenlost13" },
		@{ @"name" : @"pengubow", @"url" : @"https://github.com/pengubow" },
		@{ @"name" : @"Cooper (coopeeo)", @"url" : @"https://github.com/coopeeo" },
	];

	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
	[[self tableView] setTranslatesAutoresizingMaskIntoConstraints:NO];
	[[self tableView] setDelegate:self];
	[[self tableView] setDataSource:self];
	[[self view] addSubview:self.tableView];
	// https://github.com/reactwg/react-native-new-architecture/blob/76d8426c27c1bf30c235f653e425ef872554a33b/docs/fabric-native-components.md
	[NSLayoutConstraint activateConstraints:@[
		[self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];

	[[self view] setBackgroundColor:[Theming getBackgroundColor]];
	[[[self navigationController] navigationBar] setPrefersLargeTitles:YES];

	// i mean thats what onAppear is... right?
	[AppDelegate setImportSideStoreCertFunc:^(NSData* certData, NSString* password) {
		AppLog(@"Import Cert Func");
		[[LCUtils appGroupUserDefault] setObject:certData forKey:@"LCCertificateData"];
		[[LCUtils appGroupUserDefault] setObject:password forKey:@"LCCertificatePassword"];
		[[LCUtils appGroupUserDefault] setObject:[NSDate now] forKey:@"LCCertificateUpdateDate"];
		[self.tableView reloadData];
		[Utils showNotice:self title:@"jitless.cert.success".loc];
	}];

	// why does landscape not allow closing? we will never know...
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(onDismiss)];
}
- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
}
- (void)onDismiss {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return [[Utils getPrefs] boolForKey:@"DEVELOPER_MODE"] ? 8 : 7;
}

- (BOOL)isIOSVersionGreaterThanOrEqualTo:(NSString*)version {
	return ([[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] != NSOrderedAscending);
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
	case 0: // General
		return 7;
	case 1: // Gameplay
		return 4;
	case 2: // JIT
		if ([Utils isSandboxed] && !([self isIOSVersionGreaterThanOrEqualTo:@"19"]) && ![[Utils getPrefs] integerForKey:@"JITLESS"] && [Utils isDevCert]) {
			if ([[Utils getPrefs] integerForKey:@"JIT_ENABLER"] == 4) {
				return 3;
			} else if ([[Utils getPrefs] integerForKey:@"JIT_ENABLER"] == 3) {
				return 2;
			}
		} else {
			return 0;
		}
		return 1;
	case 3: // JIT-Less
		if ([Utils isSandboxed]) {
			if ([Utils isDevCert]) {
				return 7;
			} else {
				if ([[Utils getPrefs] integerForKey:@"ENTERPRISE_MODE"]) {
					return 5;
				} else {
					return 8;
				}
			}
		} else {
			return 0;
		}
	case 4: // Advanced
		return 6;
	case 5: // About
		return 4;
	case 6: // Credits
		return [self.creditsArray count];
	case 7: // Developer
		return 22;
	default:
		return 0;
	}
}

- (UISwitch*)createSwitch:(BOOL)enabled tag:(NSInteger)tag disable:(BOOL)disable {
	UISwitch* uiSwitch = [[UISwitch alloc] init];
	[uiSwitch setOn:enabled];
	[uiSwitch setTag:tag];
	[uiSwitch setEnabled:!disable];
	[uiSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
	return uiSwitch;
	/*UIButton* uiSwitch = [UIButton buttonWithType:UIButtonTypeSystem];
	[uiSwitch setEnabled:!disable];
	[uiSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventTouchUpInside];
	return uiSwitch;*/
}

- (void)showDevMode:(UILongPressGestureRecognizer*)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan && ![[Utils getPrefs] boolForKey:@"DEVELOPER_MODE"]) {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"developer.warning.title".loc message:@"developer.warning.msg".loc
																preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"common.yes".loc style:UIAlertActionStyleDefault handler:^(UIAlertAction* _Nonnull action) {
			[[Utils getPrefs] setBool:YES forKey:@"DEVELOPER_MODE"];
			[self.tableView reloadData];
		}];
		UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"common.no".loc style:UIAlertActionStyleCancel handler:nil];
		[alert addAction:yesAction];
		[alert addAction:noAction];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	UITableViewCell* cellval1 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];

	BOOL disableJITLess = ![Utils isSandboxed] || [[Utils getPrefs] integerForKey:@"ENTERPRISE_MODE"];
	// i wish i could case(0,0) :(
	switch (indexPath.section) {
	case 0:
		if (indexPath.row == 0) {
			cell.textLabel.text = @"general.accent-color".loc;
			UIView* colView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
			colView.backgroundColor = [Theming getAccentColor];
			colView.layer.cornerRadius = colView.frame.size.width / 2;
			cell.accessoryView = colView;
		} else if (indexPath.row == 1) {
			cell.textLabel.text = @"general.reset-accent-color".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 2) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			UISegmentedControl* control = [[UISegmentedControl alloc] initWithItems:@[ @"general.theme.system".loc, @"general.theme.light".loc, @"general.theme.dark".loc ]];
			cellval1.accessoryView = control;
			// cellval1.separatorInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, CGFLOAT_MAX);
			control.autoresizingMask =
				UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
			control.center = CGPointMake(cell.contentView.bounds.size.width / 1.5, cell.contentView.bounds.size.height / 2);
			control.selectedSegmentIndex = [[Utils getPrefs] integerForKey:@"CURRENT_THEME"];
			[control addTarget:self action:@selector(themeSelected:) forControlEvents:UIControlEventValueChanged];
			cellval1.textLabel.text = @"general.theme".loc;
			return cellval1;
		} else if (indexPath.row == 3) {
			cell.textLabel.text = @"general.change-icon".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else if (indexPath.row == 4) {
			cell.textLabel.text = @"general.open-fm".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 5) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"general.enable-updates".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"UPDATE_AUTOMATICALLY"] tag:0 disable:NO];
			return cellval1;
		} else if (indexPath.row == 6) {
			cell.textLabel.text = @"general.check-updates".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		break;
	case 1:
		if (indexPath.row == 0) {
			cell.textLabel.text = @"gameplay.safe-mode".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 1) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"gameplay.auto-launch".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"LOAD_AUTOMATICALLY"] tag:1 disable:NO];
			return cellval1;
		} else if (indexPath.row == 2) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"gameplay.fix-rotation".loc;
			if (![Utils isSandboxed] || [[Utils getPrefs] integerForKey:@"ENTERPRISE_MODE"]) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"FIX_ROTATION"] tag:5
												disable:![Utils isSandboxed] || [[Utils getPrefs] integerForKey:@"ENTERPRISE_MODE"]];
			return cellval1;
		}
		if (indexPath.row == 3) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"gameplay.fix-black-screen".loc;
			if (![Utils isSandboxed] || [[Utils getPrefs] integerForKey:@"ENTERPRISE_MODE"]) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"FIX_BLACKSCREEN"] tag:8
												disable:![Utils isSandboxed] || [[Utils getPrefs] integerForKey:@"ENTERPRISE_MODE"]];
			return cellval1;
		}
		break;
	case 2: {
		if (indexPath.row == 0) {
			cellval1.textLabel.text = @"jit.jit-enabler".loc;
			if (NSClassFromString(@"LCSharedUtils")) {
				cellval1.detailTextLabel.text = @"jit.jit-enabler.livecontainer".loc;
				cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			} else {
				cellval1.detailTextLabel.text = [self getJITEnablerOptions][[[Utils getPrefs] integerForKey:@"JIT_ENABLER"]];
			}
			cellval1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			return cellval1;
		} else if (indexPath.row == 1) {
			UITextField* textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
			textField.textAlignment = NSTextAlignmentRight;
			textField.delegate = self;
			textField.returnKeyType = UIReturnKeyDone;
			textField.autocorrectionType = UITextAutocorrectionTypeNo;
			textField.keyboardType = UIKeyboardTypeURL;
			textField.tag = 0;
			cell.accessoryView = textField;
			cell.textLabel.text = @"jit.jit-server".loc;
			if ([[Utils getPrefs] integerForKey:@"JIT_ENABLER"] == 4) {
				textField.placeholder = @"http://x.x.x.x:8080";
			} else {
				textField.placeholder = @"http://[fd00::]:9172";
			}
			textField.text = [[Utils getPrefs] stringForKey:@"SideJITServerAddr"];
		} else if (indexPath.row == 2) {
			UITextField* textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
			textField.textAlignment = NSTextAlignmentRight;
			textField.delegate = self;
			textField.returnKeyType = UIReturnKeyDone;
			textField.autocorrectionType = UITextAutocorrectionTypeNo;
			textField.tag = 1;
			cell.accessoryView = textField;
			cell.textLabel.text = @"jit.jit-udid".loc;
			textField.placeholder = @"00008020-008D4548007B4F26";
			textField.text = [[Utils getPrefs] stringForKey:@"JITDeviceUDID"];
		}
		break;
	}
	case 3: {
		NSInteger row = indexPath.row;
		if (![Utils isDevCert])
			row--;
		if (row == -1) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"jitless.enterprise".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"] tag:16 disable:NO];
			return cellval1;
		} else if (row == 0 && [[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
			cell.textLabel.text = @"Launch without patching";
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (row == 0 && ![[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"jitless.enable".loc;
			if (disableJITLess) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"JITLESS"] tag:9 disable:disableJITLess];
			return cellval1;
		} else if (row == 1 && [[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
			cell.textLabel.text = @"Force Reset Patching";
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (row == 1 && ![[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
			cell.textLabel.text = @"jitless.diag".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else if (row == 2 && ![[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"jitless.certstatus".loc;
			if ([LCUtils certificateData] != nil) {
				[LCUtils validateCertificate:^(int status, NSDate* expirationDate, NSString* errorC) {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (errorC != nil || status != 0 || expirationDate == nil) {
							AppLog(@"Invalid certificate: \"%@\", %i", errorC, status);
							cellval1.detailTextLabel.textColor = [UIColor systemRedColor];
							cellval1.detailTextLabel.text = @"jitless.certstatus.invalid".loc;
						} else {
							NSCalendar* calendar = [NSCalendar currentCalendar];
							NSDateComponents* components = [calendar components:NSCalendarUnitDay fromDate:[NSDate date] toDate:expirationDate options:0];
							NSInteger days = [components day];
							if (days < 30) {
								cellval1.detailTextLabel.textColor = [UIColor systemOrangeColor];
							} else if (days < 90) {
								cellval1.detailTextLabel.textColor = [UIColor systemYellowColor];
							} else {
								cellval1.detailTextLabel.textColor = [UIColor systemGreenColor];
							}
							if (days < 0) {
								cellval1.detailTextLabel.text = [NSString stringWithFormat:@"jitless.certstatus.expired".loc, (long)days];
							} else {
								cellval1.detailTextLabel.text = [NSString stringWithFormat:@"jitless.certstatus.valid".loc, (long)days];
							}
						}
					});
				}];
			} else {
				cellval1.detailTextLabel.text = @"jitless.certstatus.notimport".loc;
			}
			return cellval1;
		} else if (row == 2 && [[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
			cell.textLabel.text = @"Install Helper";
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (row == 3 && [[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
			cell.textLabel.text = @"Setup Steps";
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (row == 3 && ![[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
			if ((![LCUtils isAppGroupAltStoreLike] && [LCUtils appGroupID] == nil) || [[Utils getPrefs] boolForKey:@"MANUAL_IMPORT_CERT"]) {
				if ([[Utils getPrefs] boolForKey:@"LCCertificateImported"]) {
					cell.textLabel.text = @"Remove Certificate";
				} else {
					cell.textLabel.text = @"Import Certificate Manually";
				}
				cell.textLabel.textColor = [Theming getAccentColor];
				cell.accessoryType = UITableViewCellAccessoryNone;
			} else {
				cell.textLabel.text = [NSString stringWithFormat:@"Patch %@", [LCUtils getStoreName]];
				if ([LCUtils store] == SideStore) {
					if ([LCUtils certificateData] != nil) {
						cell.textLabel.text = [NSString stringWithFormat:@"Refresh Certificate from %@", [LCUtils getStoreName]];
					} else {
						cell.textLabel.text = [NSString stringWithFormat:@"Import Certificate from %@", [LCUtils getStoreName]];
					}
				}
				cell.textLabel.textColor = [Theming getAccentColor];
			}
			cell.accessoryType = UITableViewCellAccessoryNone;
			if (NSClassFromString(@"LCSharedUtils")) {
				cell.textLabel.text = @"Follow the LiveContainer guide";
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.textLabel.textColor = [UIColor systemGrayColor];
			}
		} else if (row == 4) {
			cell.textLabel.text = @"Test JIT-Less Mode";
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (row == 5) {
			cell.textLabel.text = @"Force Resign";
			if (![[Utils getPrefs] boolForKey:@"JITLESS"]) {
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.textLabel.textColor = [UIColor systemGrayColor];
			} else {
				cell.textLabel.textColor = [Theming getAccentColor];
			}
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (row == 6) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"Allow Importing Cert".loc;
			if (disableJITLess) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"MANUAL_IMPORT_CERT"] tag:19 disable:disableJITLess];
			return cellval1;
		}
		break;
	}
	case 4:
		if (indexPath.row == 0) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.accessoryView =
				[self createSwitch:[[Utils getPrefs] boolForKey:@"MANUAL_REOPEN"] tag:7
						   disable:![Utils isSandboxed] || ([self isIOSVersionGreaterThanOrEqualTo:@"19"]) || [[Utils getPrefs] integerForKey:@"JITLESS"] || ![Utils isDevCert]];
			cellval1.textLabel.text = @"advanced.manual-reopen-jit".loc;
			if (![Utils isSandboxed] || ([self isIOSVersionGreaterThanOrEqualTo:@"19"]) || [[Utils getPrefs] integerForKey:@"JITLESS"] || ![Utils isDevCert]) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			return cellval1;
		} else if (indexPath.row == 1) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"USE_NIGHTLY"] tag:11 disable:NO];
			cellval1.textLabel.text = @"advanced.use-nightly".loc;
			return cellval1;
		} else if (indexPath.row == 2) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.accessoryView = [self createSwitch:![[Utils getPrefs] boolForKey:@"DONT_WARN_JIT"] tag:13 disable:NO];
			cellval1.textLabel.text = @"advanced.warn-launcher-jit".loc;
			return cellval1;
		} else if (indexPath.row == 3) {
			cell.textLabel.text = @"advanced.view-app-logs".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else if (indexPath.row == 4) {
			cell.textLabel.text = @"advanced.view-recent-logs".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else if (indexPath.row == 5) {
			cell.textLabel.text = @"advanced.view-recent-crash".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		break;
	case 5: {
		cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
		if (indexPath.row == 0) {
			cellval1.textLabel.text = @"about.launcher".loc;
			cellval1.detailTextLabel.text = [NSString stringWithFormat:@"v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
			cellval1.textLabel.userInteractionEnabled = YES;
			UILongPressGestureRecognizer* longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showDevMode:)];
			[cellval1.textLabel addGestureRecognizer:longPressGR];
		} else if (indexPath.row == 1) {
			cellval1.textLabel.text = @"about.geode".loc;
			cellval1.detailTextLabel.text = [Utils getGeodeVersion];
		} else if (indexPath.row == 2) {
			NSString* infoPlistPath;
			if (![Utils isSandboxed]) {
				infoPlistPath = [[Utils getGDBundlePath] stringByAppendingPathComponent:@"GeometryJump.app/Info.plist"];
			} else {
				infoPlistPath = [[[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]] URLByAppendingPathComponent:@"Info.plist"].path;
			}
			NSDictionary* infoDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
			cellval1.textLabel.text = @"about.geometry-dash".loc;
			cellval1.detailTextLabel.text = [NSString stringWithFormat:@"v%@", [infoDictionary objectForKey:@"CFBundleShortVersionString"]];
		} else if (indexPath.row == 3) {
			cellval1.textLabel.text = @"about.device".loc;
			NSString* model = [[UIDevice currentDevice] localizedModel];
			NSString* systemName = [[UIDevice currentDevice] systemName];
			NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
			cellval1.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ (%@,%@)", systemName, systemVersion, model, [Utils archName]];
		}
		return cellval1;
	}
	case 6: {
		cell.textLabel.text = self.creditsArray[indexPath.row][@"name"];
		cell.textLabel.textColor = [Theming getAccentColor];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
	case 7: {
		if (indexPath.row == 0) {
			UITextField* textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
			textField.textAlignment = NSTextAlignmentRight;
			textField.delegate = self;
			textField.returnKeyType = UIReturnKeyDone;
			textField.autocorrectionType = UITextAutocorrectionTypeNo;
			textField.tag = 3;
			cell.accessoryView = textField;
			cell.textLabel.text = @"developer.launchargs".loc;
			textField.placeholder = @"--geode:safe-mode";
			textField.text = [[Utils getPrefs] stringForKey:@"LAUNCH_ARGS"];
		} else if (indexPath.row == 1) {
			UITextField* textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
			textField.textAlignment = NSTextAlignmentRight;
			textField.delegate = self;
			textField.returnKeyType = UIReturnKeyDone;
			textField.autocorrectionType = UITextAutocorrectionTypeNo;
			textField.tag = 4;
			cell.accessoryView = textField;
			cell.textLabel.text = @"Last Nightly Date";
			textField.placeholder = @"2022-20505025";
			textField.text = [[Utils getPrefs] stringForKey:@"NIGHTLY_DATE"];
		} else if (indexPath.row == 2) {
			UITextField* textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
			textField.textAlignment = NSTextAlignmentRight;
			textField.delegate = self;
			textField.returnKeyType = UIReturnKeyDone;
			textField.autocorrectionType = UITextAutocorrectionTypeNo;
			textField.tag = 2;
			cell.accessoryView = textField;
			cell.textLabel.text = @"Reinstall URL";
			textField.placeholder = @"apple-magnifier://install?url=http://x.x.x.x:3000";
			textField.text = [[Utils getPrefs] stringForKey:@"DEV_REINSTALL_ADDR"];
		} else if (indexPath.row == 3) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"advanced.dev-mode".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"DEVELOPER_MODE"] tag:2 disable:NO];
			return cellval1;
		} else if (indexPath.row == 4) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"developer.completedsetup".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"CompletedSetup"] tag:6 disable:NO];
			return cellval1;
		} else if (indexPath.row == 5) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"developer.webserver".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"WEB_SERVER"] tag:12 disable:NO];
			return cellval1;
		} else if (indexPath.row == 6) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"Force Patching".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"FORCE_PATCHING"] tag:14 disable:NO];
			return cellval1;
		} else if (indexPath.row == 7) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"Don't patch on Safe Mode".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"DONT_PATCH_SAFEMODE"] tag:15 disable:NO];
			return cellval1;
		} else if (indexPath.row == 8) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"Force Enterprise Mode".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"FORCE_ENTERPRISE"] tag:17 disable:NO];
			return cellval1;
		} else if (indexPath.row == 9) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"Is Compressing IPA".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"IS_COMPRESSING_IPA"] tag:18 disable:NO];
			return cellval1;
		} else if (indexPath.row == 10) {
			cell.textLabel.text = @"developer.testbundleaccess".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 11) {
			cell.textLabel.text = @"developer.importipa".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 12) {
			cell.textLabel.text = @"App Reinstall".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 13) {
			cell.textLabel.text = @"Copy Current Binary".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			if ([[NSFileManager defaultManager]
					fileExistsAtPath:[[[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]] URLByAppendingPathComponent:@"GeometryOriginal"].path]) {
				cell.textLabel.textColor = [UIColor systemGrayColor];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
		} else if (indexPath.row == 14) {
			cell.textLabel.text = @"Patch Binary".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 15) {
			cell.textLabel.text = @"Restore Binary".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			if (![[NSFileManager defaultManager]
					fileExistsAtPath:[[[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]] URLByAppendingPathComponent:@"GeometryOriginal"].path]) {
				cell.textLabel.textColor = [UIColor systemGrayColor];
				cell.accessoryType = UITableViewCellAccessoryNone;
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
		} else if (indexPath.row == 16) {
			cell.textLabel.text = @"Clear App Logs".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 17) {
			cell.textLabel.text = @"Patch & Share IPA".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 18) {
			cell.textLabel.text = @"Restore IPA Patch".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 19) {
			cell.textLabel.text = @"View Bundle Dir".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else if (indexPath.row == 20) {
			cell.textLabel.text = @"View Documents Dir".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else if (indexPath.row == 21) {
			cell.textLabel.text = @"View NSUserDefaults".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		break;
	}
	}

	return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
	return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
	case 0:
		return @"general".loc;
	case 1:
		return @"gameplay".loc;
	case 2:
		if ([Utils isSandboxed] && !([self isIOSVersionGreaterThanOrEqualTo:@"19"]) && ![[Utils getPrefs] integerForKey:@"JITLESS"] && [Utils isDevCert]) {
			return @"jit".loc;
		} else {
			return @"";
		}
	case 3:
		if ([Utils isSandboxed]) {
			return @"jitless".loc;
		} else {
			return @"";
		}
	case 4:
		return @"advanced".loc;
	case 5:
		return @"about".loc;
	case 6:
		return @"credits".loc;
	case 7:
		return @"developer".loc;
	default:
		return @"Unknown";
	}
}

// TODO: Replace Manual Reopen with JIT to be in the JIT Enabler
- (NSArray*)getJITEnablerOptions {
	NSString* tsPath = [NSString stringWithFormat:@"%@/../_TrollStore", [NSBundle mainBundle].bundlePath];
	if (NSClassFromString(@"LCSharedUtils")) {
		return @[ @"", @"", @"", @"", @"", @"", @"jit.jit-enabler.livecontainer".loc ];
	}
	if (!access(tsPath.UTF8String, F_OK)) {
		return @[
			@"jit.jit-enabler.default".loc, @"jit.jit-enabler.trollstore".loc, @"jit.jit-enabler.stikjit".loc, @"jit.jit-enabler.jitstreamereb".loc, @"jit.jit-enabler.sidejit".loc,
			@"jit.jit-enabler.sidestore".loc, @""
		];
	} else {
		return @[
			@"jit.jit-enabler.default".loc, @"", @"jit.jit-enabler.stikjit".loc, @"jit.jit-enabler.jitstreamereb".loc, @"jit.jit-enabler.sidejit".loc,
			@"jit.jit-enabler.sidestore".loc, @""
		];
	}
}

- (NSString*)getJITEnablerFooter {
	switch ([[Utils getPrefs] integerForKey:@"JIT_ENABLER"]) {
	default:
	case 0: // Default
		return @"jit.footer.default".loc;
	case 1: // TrollStore
		return @"jit.footer.trollstore".loc;
	case 2: // StikJIT
		return @"jit.footer.stikjit".loc;
	case 3: // JITStreamer-EB
		return @"jit.footer.jitstreamereb".loc;
	case 4: // SideJITServer
		return @"jit.footer.sidejit".loc;
	case 5: // SideStore
		return @"jit.footer.sidestore".loc;
	case 6: // LiveContainer
		return @"jit.footer.livecontainer".loc;
	}
}

- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section {
	switch (section) {
	case 0:
		return [@"general.footer" localizeWithFormat:[Utils getGeodeVersion]];
	case 1:
		return @"gameplay.footer".loc;
	case 2:
		if (![Utils isSandboxed] || ([self isIOSVersionGreaterThanOrEqualTo:@"19"]) || [[Utils getPrefs] integerForKey:@"JITLESS"] || ![Utils isDevCert])
			return @"";
		if (NSClassFromString(@"LCSharedUtils"))
			return @"jit.footer.livecontainer".loc;
		return [self getJITEnablerFooter];
	case 3:
		if (![Utils isSandboxed])
			return @"";
		return @"jitless.footer".loc;
	case 6:
		return @"credits.footer".loc;
	default:
		return nil;
	}
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if (indexPath.section == 0) {
		switch (indexPath.row) {
		case 0: { // Change accent color
			MSColorSelectionViewController* colorSelectionController = [[MSColorSelectionViewController alloc] init];
			UINavigationController* navCtrl = [[UINavigationController alloc] initWithRootViewController:colorSelectionController];

			// fix transparent issue
			UINavigationBarAppearance* appearance = [[UINavigationBarAppearance alloc] init];
			[appearance configureWithOpaqueBackground];
			appearance.backgroundColor = [UIColor systemBackgroundColor];

			navCtrl.navigationBar.standardAppearance = appearance;
			navCtrl.navigationBar.scrollEdgeAppearance = appearance;

			navCtrl.popoverPresentationController.delegate = self;
			navCtrl.modalInPresentation = YES;
			navCtrl.preferredContentSize = [colorSelectionController.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
			navCtrl.modalPresentationStyle = UIModalPresentationOverFullScreen;

			colorSelectionController.delegate = self;
			colorSelectionController.color = [Theming getAccentColor];

			UIBarButtonItem* doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(ms_dismissViewController:)];
			colorSelectionController.navigationItem.rightBarButtonItem = doneBtn;
			//[[self navigationController] pushViewController:colorSelectionController animated:YES];
			[self presentViewController:navCtrl animated:YES completion:nil];
			break;
		}
		case 1: {
			[[Utils getPrefs] removeObjectForKey:@"accentColor"];
			[self.root updateState];
			[self.tableView reloadData];
			break;
		}
		case 3: { // change icon
			IconViewController* IconVC = [[IconViewController alloc] init];
			[[self navigationController] pushViewController:IconVC animated:YES];
			break;
		}
		case 4: { // Open file manager
			NSString* openURL;
			if (![Utils isSandboxed]) {
				openURL = [NSString stringWithFormat:@"filza://%@", [[Utils getGDDocPath] stringByAppendingPathComponent:@"Documents"]];
			} else {
				openURL = [NSString stringWithFormat:@"shareddocuments://%@", [[LCPath dataPath] URLByAppendingPathComponent:@"GeometryDash/Documents"].path];
			}
			NSURL* url = [NSURL URLWithString:openURL];
			if ([[UIApplication sharedApplication] canOpenURL:url]) {
				[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
			}
			break;
		}
		case 6: { // Check for updates
			[[Utils getPrefs] setObject:@"NO" forKey:@"PATCH_CHECKSUM"];
			if ([VerifyInstall verifyGeodeInstalled]) {
				[[GeodeInstaller alloc] checkUpdates:_root download:YES];
				[self dismissViewControllerAnimated:YES completion:nil];
			} else {
				[Utils showError:_root title:@"general.check-updates.error".loc error:nil];
			}
			break;
		}
		default:
			break;
		}
	} else if (indexPath.section == 1) {
		switch (indexPath.row) {
		case 0: { // Safe Mode
			if (![Utils isSandboxed]) {
				[Utils tweakLaunch_withSafeMode:true];
				break;
			}
			if (!_root.launchButton.enabled) {
				[Utils showError:self title:@"The game is already launching! Please wait." error:nil];
				break;
			}
			if ([[Utils getPrefs] boolForKey:@"MANUAL_REOPEN"] && ![[Utils getPrefs] boolForKey:@"JITLESS"]) {
				[[Utils getPrefs] setValue:[Utils gdBundleName] forKey:@"selected"];
				[[Utils getPrefs] setValue:@"GeometryDash" forKey:@"selectedContainer"];
				[[Utils getPrefs] setBool:YES forKey:@"safemode"];
				NSFileManager* fm = [NSFileManager defaultManager];
				[fm createFileAtPath:[[LCPath docPath] URLByAppendingPathComponent:@"jitflag"].path contents:[[NSData alloc] init] attributes:@{}];
				if (NSClassFromString(@"LCSharedUtils")) {
					[Utils showNotice:self title:@"launcher.relaunch-notice.lc".loc];
				} else {
					[Utils showNotice:self title:@"launcher.relaunch-notice".loc];
				}
			} else {
				if (![[Utils getPrefs] boolForKey:@"DONT_PATCH_SAFEMODE"] && [[Utils getPrefs] boolForKey:@"JITLESS"]) {
					[_root.launchButton setEnabled:NO];
					[_root signAppWithSafeMode:^(BOOL success, NSString* error) {
						dispatch_async(dispatch_get_main_queue(), ^{
							if (!success) {
								[Utils showError:self title:error error:nil];
								[_root.launchButton setEnabled:YES];
								return;
							}
							if (NSClassFromString(@"LCSharedUtils")) {
								[[Utils getPrefs] setValue:[Utils gdBundleName] forKey:@"selected"];
								[[Utils getPrefs] setValue:@"GeometryDash" forKey:@"selectedContainer"];
								[[Utils getPrefs] setBool:YES forKey:@"safemode"];
								AppLog(@"Launching in Safe Mode");
								if (![LCUtils launchToGuestApp]) {
									[Utils showErrorGlobal:[NSString stringWithFormat:@"launcher.error.gd".loc, @"launcher.error.app-uri".loc] error:nil];
								}
							} else {
								NSString* openURL =
									[NSString stringWithFormat:@"%@://safe-mode", NSBundle.mainBundle.infoDictionary[@"CFBundleURLTypes"][0][@"CFBundleURLSchemes"][0]];
								NSURL* url = [NSURL URLWithString:openURL];
								if ([[UIApplication sharedApplication] canOpenURL:url]) {
									[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
									[self dismissViewControllerAnimated:YES completion:nil];
								}
							}
						});
					}];
				} else if ([[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
					[self dismissViewControllerAnimated:YES completion:nil];
					[_root.launchButton setEnabled:NO];
					[_root launchHelper2:YES patchCheck:NO];
				} else {
					if (NSClassFromString(@"LCSharedUtils")) {
						[[Utils getPrefs] setValue:[Utils gdBundleName] forKey:@"selected"];
						[[Utils getPrefs] setValue:@"GeometryDash" forKey:@"selectedContainer"];
						[[Utils getPrefs] setBool:YES forKey:@"safemode"];
						AppLog(@"Launching in Safe Mode");
						if (![LCUtils launchToGuestApp]) {
							[Utils showErrorGlobal:[NSString stringWithFormat:@"launcher.error.gd".loc, @"launcher.error.app-uri".loc] error:nil];
						}
					} else {
						NSString* openURL = [NSString stringWithFormat:@"%@://safe-mode", NSBundle.mainBundle.infoDictionary[@"CFBundleURLTypes"][0][@"CFBundleURLSchemes"][0]];
						NSURL* url = [NSURL URLWithString:openURL];
						if ([[UIApplication sharedApplication] canOpenURL:url]) {
							[_root.launchButton setEnabled:NO];
							[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
							[self dismissViewControllerAnimated:YES completion:nil];
						}
					}
				}
			}
			break;
		}
		}
	} else if (indexPath.section == 2) {
		switch (indexPath.row) {
		case 0: {
			if (NSClassFromString(@"LCSharedUtils"))
				break;
			UIAlertController* alert = [UIAlertController
				alertControllerWithTitle:@"jit.jit-enabler".loc
								 message:nil
						  preferredStyle:[UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
			// no thanks not dealing with setting the view
			// https://stackoverflow.com/questions/31577140/uialertcontroller-is-crashed-ipad
			for (NSInteger i = 0; i < [self getJITEnablerOptions].count; i++) {
				NSString* value = [self getJITEnablerOptions][i];
				if (![value isEqualToString:@""]) {
					[alert addAction:[UIAlertAction actionWithTitle:[self getJITEnablerOptions][i] style:UIAlertActionStyleDefault handler:^(UIAlertAction* _Nonnull action) {
							   [[Utils getPrefs] setInteger:i forKey:@"JIT_ENABLER"];
							   [self.tableView reloadData];
						   }]];
				}
			}

			[alert addAction:[UIAlertAction actionWithTitle:@"common.cancel".loc style:UIAlertActionStyleCancel handler:nil]];

			[self presentViewController:alert animated:YES completion:nil];
			/*UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

			NSArray *options = @[@"Option 1", @"Option 2", @"Option 3", @"Option 4"];

			CGPoint anchorPoint = CGPointMake(CGRectGetMidX(cell.frame), CGRectGetMaxY(cell.frame));

			anchorPoint = [tableView convertPoint:anchorPoint toView:self.view];

			DropdownView *dropdown = [[DropdownView alloc] initWithItems:options anchorPoint:anchorPoint width:200.0];
			dropdown.delegate = self;
			[dropdown show];

			[tableView deselectRowAtIndexPath:indexPath animated:YES];*/
			break;
		}
		}
	} else if (indexPath.section == 3) {
		switch (indexPath.row) {
		case 1: { // JIT-Less diagnose
			if (![[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
				JITLessVC* view = [[JITLessVC alloc] init];
				[[self navigationController] pushViewController:view animated:YES];
			} else { // launch without patching
				[_root launchHelper2:NO patchCheck:NO];
			}
			break;
		}
		case 2: {
			if (![[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"])
				break;
			[[Utils getPrefs] setObject:@"NO" forKey:@"PATCH_CHECKSUM"];
			[Utils showNotice:self title:@"Forced! Now the launcher will start patching again upon tapping launch."];
		}
		case 3: { // Patch / Import
			if ([[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
				NSFileManager* fm = [NSFileManager defaultManager];
				NSString* extractionPath = [[fm temporaryDirectory] URLByAppendingPathComponent:@"Helper.ipa"].path;
				NSURL* extractionPathURL = [NSURL fileURLWithPath:extractionPath];
				if (![fm fileExistsAtPath:extractionPath]) {
					[Utils showError:self title:@"Helper IPA doesn't exist! Tap Launch to generate one." error:nil];
					break;
				}
				UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ extractionPathURL ] applicationActivities:nil];
				// not sure if this is even necessary because ive never seen anyone complain about app logs
				if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
					activityViewController.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0, 0);
					activityViewController.popoverPresentationController.permittedArrowDirections = 0;
				}
				activityViewController.popoverPresentationController.sourceView = self.view;
				[self presentViewController:activityViewController animated:YES completion:nil];
				break;
			}
			if (NSClassFromString(@"LCSharedUtils")) {
				break;
			}
			if (![LCUtils isAppGroupAltStoreLike] || [[Utils getPrefs] boolForKey:@"MANUAL_IMPORT_CERT"]) {
				if ([[Utils getPrefs] boolForKey:@"LCCertificateImported"]) {
					UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Are you sure you want to remove your certificate?"
																			preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* _Nonnull action) {
						NSUserDefaults* NSUD = [Utils getPrefs];
						[NSUD setObject:nil forKey:@"LCCertificatePassword"];
						[NSUD setObject:nil forKey:@"LCCertificateData"];
						[NSUD setBool:NO forKey:@"LCCertificateImported"];
						[self.tableView reloadData];
						[Utils showNotice:self title:@"Certificate removed."];
					}];
					UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
					[alert addAction:okAction];
					[alert addAction:cancelAction];
					[self presentViewController:alert animated:YES completion:nil];
					break;
				}
				if (![Utils isDevCert]) {
					[Utils showError:self title:@"jitless.cert.dev-cert".loc error:nil];
					break;
				}
				_isImportCert = true;
				// https://developer.apple.com/documentation/uniformtypeidentifiers/uttype-swift.struct/pkcs12
				// public.x509-certificate
				UTType* type = [UTType typeWithIdentifier:@"com.rsa.pkcs-12"];
				if (!type) {
					type = [UTType typeWithFilenameExtension:@"p12"];
				}
				if (!type) {
					type = [UTType typeWithIdentifier:@"public.data"];
				}
				if (!type) {
					// what is going on apple
					AppLog(@"Couldn't find any valid UTType. Not opening to prevent crashing.");
					break;
				}
				UIDocumentPickerViewController* picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[ type ] asCopy:YES];
				picker.delegate = self;
				picker.allowsMultipleSelection = NO;
				[self presentViewController:picker animated:YES completion:nil];
			} else {
				NSString* storeName = [LCUtils getStoreName];
				BOOL isSideStore = [LCUtils store] == SideStore;
				if (isSideStore) {
					NSURL* url = [NSURL
						URLWithString:
							[NSString stringWithFormat:
										  @"%@://certificate?callback_template=%@%%3A%%2F%%2Fcertificate%%3Fcert%%3D%%24%%28BASE64_CERT%%29%%26password%%3D%%24%%28PASSWORD%%29",
										  [[LCUtils getStoreName] lowercaseString], NSBundle.mainBundle.infoDictionary[@"CFBundleURLTypes"][0][@"CFBundleURLSchemes"][0]]];
					AppLog(@"using %@", url);
					if ([[UIApplication sharedApplication] canOpenURL:url]) {
						[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
					}
				} else {
					//%1$@
					UIAlertController* alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Patch %@", storeName]
																				   message:@"AltStore is not supported yet. Please use SideStore instead."
																			preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
					[alert addAction:cancelAction];
					[self presentViewController:alert animated:YES completion:nil];
				}
			}
			break;
		}
		case 4: { // Test JIT-Less
			if ([[Utils getPrefs] boolForKey:@"ENTERPRISE_MODE"]) {
				[Utils showNotice:self title:@"launcher.notice.enterprise.s2".loc];
				break;
			}
			if ([LCUtils certificateData]) {
				[LCUtils validateCertificate:^(int status, NSDate* expirationDate, NSString* errorC) {
					if (errorC) {
						return [Utils showError:self title:[NSString stringWithFormat:@"launcher.error.sign.invalidcert".loc, errorC] error:nil];
					}
					if (status != 0) {
						return [Utils showError:self title:@"launcher.error.sign.invalidcert2".loc error:nil];
					}
					[LCUtils validateJITLessSetup:^(BOOL success, NSError* error) {
						if (success) {
							return [Utils
								showNotice:self
									 title:[NSString stringWithFormat:@"JIT-Less Mode Test Passed!\nApp Group ID: %@\nStore: %@", [LCUtils appGroupID], [LCUtils getStoreName]]];
						} else {
							AppLog(@"JIT-Less test failed: %@", error);
							return [Utils
								showError:self
									title:[NSString stringWithFormat:@"The test library has failed to load. This means your certificate may be having issue. Please try to: 1. "
																	 @"Reopen %@; 2. Refresh all apps in %@; 3. Re-patch %@ and try again.\n\nIf you imported certificate, "
																	 @"please ensure the certificate is valid, and it is NOT an enterprise certificate.",
																	 [LCUtils getStoreName], [LCUtils getStoreName], [LCUtils getStoreName]]
									error:nil];
						}
					}];
				}];
			} else {
				[Utils showError:self title:@"You did not sideload this app with AltStore or SideStore! Or you didn't import a certificate.".loc error:nil];
			}
			break;
		}
		case 5: { // Force Resign
			if (![[Utils getPrefs] boolForKey:@"JITLESS"])
				break;
			return [_root signApp:YES completionHandler:^(BOOL success, NSString* error) {
				dispatch_async(dispatch_get_main_queue(), ^{
					if (!success) {
						[Utils showError:self title:error error:nil];
					} else {
						[Utils showNotice:self title:@"Resign successful!"];
					}
					[tableView deselectRowAtIndexPath:indexPath animated:YES];
				});
			}];
		}
		}
	} else if (indexPath.section == 4) {
		switch (indexPath.row) {
		case 3: { // View app logs
			[[self navigationController] pushViewController:[[LogsViewController alloc] initWithFile:[[LCPath docPath] URLByAppendingPathComponent:@"app.log"]] animated:YES];
			break;
		}
		case 4: { // View geode logs
			NSURL* file = [Utils pathToMostRecentLogInDirectory:[[Utils docPath] stringByAppendingString:@"game/geode/logs/"]];
			[[self navigationController] pushViewController:[[LogsViewController alloc] initWithFile:file] animated:YES];
			break;
		}
		case 5: { // View recent crash
			NSURL* file = [Utils pathToMostRecentLogInDirectory:[[Utils docPath] stringByAppendingString:@"game/geode/crashlogs/"]];
			[[self navigationController] pushViewController:[[LogsViewController alloc] initWithFile:file] animated:YES];
			break;
		}
		}
	} else if (indexPath.section == 6) {
		NSURL* url = [NSURL URLWithString:self.creditsArray[indexPath.row][@"url"]];
		if ([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]) {
			[[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
		}
	} else if (indexPath.section == 7) {
		NSFileManager* fm = [NSFileManager defaultManager];
		NSURL* bundlePath = [[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]];
		switch (indexPath.row) {
		case 10: { // Test GD Bundle Access (testbundleaccess) why do i always use it for testing? its quicker!
			[Utils showNotice:self title:[Utils getGDDocPath]];
			break;
		}
		case 11: { // Import IPA
			_isImportIPA = true;
			UTType* type = [UTType typeWithIdentifier:@"com.apple.itunes.ipa"];
			if (!type) {
				type = [UTType typeWithFilenameExtension:@"ipa"];
			}
			if (!type) {
				type = [UTType typeWithIdentifier:@"public.data"];
			}
			if (!type) {
				// what is going on apple
				AppLog(@"Couldn't find any valid UTType. Not opening to prevent crashing.");
				break;
			}
			UIDocumentPickerViewController* picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[ type ] asCopy:YES];
			picker.delegate = self;
			picker.allowsMultipleSelection = NO;
			[self presentViewController:picker animated:YES completion:nil];
			break;
		}
		case 12: { // TS App Reinstall
			NSURL* url = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"DEV_REINSTALL_ADDR"]];
			if ([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]) {
				[[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
			}
			break;
		}
		case 13: { // Copy Current Binary
			if ([fm fileExistsAtPath:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"].path]) {
				break;
			} else {
				NSError* err;
				[fm copyItemAtURL:[bundlePath URLByAppendingPathComponent:@"GeometryJump"] toURL:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"] error:&err];
				if (err) {
					[Utils showError:self title:@"Couldn't copy binary" error:err];
				} else {
					[Utils showNotice:self title:@"Binary copied!"];
					[self.tableView reloadData];
				}
			}
			break;
		}
		case 14: { // Patch
			if (![fm fileExistsAtPath:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"].path]) {
				[Utils showError:self title:@"Original Binary not found." error:nil];
			} else {
				[Patcher patchGDBinary:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"] to:[bundlePath URLByAppendingPathComponent:@"GeometryJump"]
					withHandlerAddress:0x8b8000
								 force:YES
						  withSafeMode:NO
					  withEntitlements:YES completionHandler:^(BOOL success, NSString* error) {
						  dispatch_async(dispatch_get_main_queue(), ^{
							  if (success) {
								  [Utils showNotice:self title:@"Patched!"];
							  } else {
								  [Utils showError:self title:error error:nil];
							  }
						  });
					  }];
			}
			break;
		}
		case 15: { // Restore Binary
			if (![fm fileExistsAtPath:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"].path]) {
				break;
			} else {
				NSError* err;
				[fm removeItemAtURL:[bundlePath URLByAppendingPathComponent:@"GeometryJump"] error:&err];
				if (err) {
					[Utils showError:self title:@"Couldn't remove patched binary" error:err];
					break;
				}
				[fm copyItemAtURL:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"] toURL:[bundlePath URLByAppendingPathComponent:@"GeometryJump"] error:&err];
				if (err) {
					[Utils showError:self title:@"Couldn't copy binary" error:err];
				} else {
					[[Utils getPrefs] setObject:@"NO" forKey:@"PATCH_CHECKSUM"];
					[Utils showNotice:self title:@"Original Binary restored!"];
				}
			}
			break;
		}
		case 16: { // Clear App Log
			[LogUtils clearLogs:YES];
			[Utils showNotice:self title:@"App Logs Cleared!"];
			break;
		}
		case 17: { // Patch & Share IPA
			NSFileManager* fm = [NSFileManager defaultManager];
			NSString* infoPath = [bundlePath URLByAppendingPathComponent:@"Info.plist"].path;
			NSString* infoBackupPath = [bundlePath URLByAppendingPathComponent:@"InfoBackup.plist"].path;
			NSError* err;
			if (![fm fileExistsAtPath:infoBackupPath]) {
				[fm copyItemAtPath:infoPath toPath:infoBackupPath error:&err];
				if (err) {
					[Utils showError:self title:@"Failed to copy Info.plist" error:err];
					break;
				}
			}
			if ([fm fileExistsAtPath:infoBackupPath]) {
				NSMutableDictionary* infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoBackupPath];
				if (!infoDict)
					break;

				infoDict[@"CFBundleDisplayName"] = @"Geode Helper";
				infoDict[@"CFBundleIdentifier"] = @"com.geode.helper";
				infoDict[@"GCSupportsControllerUserInteraction"] = @YES;
				infoDict[@"GCSupportsGameMode"] = @YES;
				infoDict[@"LSApplicationCategoryType"] = @"public.app-category.games";
				infoDict[@"CADisableMinimumFrameDurationOnPhone"] = @YES;
				infoDict[@"UISupportsDocumentBrowser"] = @YES; // is this necessary? dunno
				infoDict[@"UIFileSharingEnabled"] = @YES;
				infoDict[@"LSSupportsOpeningDocumentsInPlace"] = @YES;
				infoDict[@"MinimumOSVersion"] = @"13.0";

				// permissions
				infoDict[@"NSMicrophoneUsageDescription"] = @"A mod you are using is requesting this permission.";
				infoDict[@"NSCameraUsageDescription"] = @"A mod you are using is requesting this permission.";
				[infoDict writeToFile:infoPath atomically:YES];
			}
			NSString* docPath = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject.path;
			NSString* tweakPath = [NSString stringWithFormat:@"%@/Tweaks/Geode.ios.dylib", docPath];
			NSString* tweakBundlePath = [bundlePath URLByAppendingPathComponent:@"Geode.ios.dylib"].path;
			if ([fm fileExistsAtPath:tweakBundlePath]) {
				NSError* removeError;
				[fm removeItemAtPath:tweakBundlePath error:&removeError];
				if (removeError) {
					[Utils showError:self title:@"Failed to delete old Geode library" error:removeError];
					break;
				}
			}
			NSString* tweakLoaderPath = [bundlePath URLByAppendingPathComponent:@"EnterpriseLoader.dylib"].path;
			if (![fm fileExistsAtPath:tweakLoaderPath]) {
				AppLog(@"invokeAppMain - Creating TweakLoader.dylib symlink");
				NSString* target = [NSBundle.mainBundle.privateFrameworksPath stringByAppendingPathComponent:@"EnterpriseLoader.dylib"];
				[fm copyItemAtPath:target toPath:tweakLoaderPath error:nil];
			}
			[fm copyItemAtPath:tweakPath toPath:tweakBundlePath error:&err];
			if (err) {
				[Utils showError:self title:@"Failed to copy Geode library" error:err];
				break;
			}
			[Patcher patchGDBinary:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"] to:[bundlePath URLByAppendingPathComponent:@"GeometryJump"]
				withHandlerAddress:0x8b8000
							 force:YES
					  withSafeMode:YES
				  withEntitlements:YES completionHandler:^(BOOL success, NSString* error) {
					  dispatch_async(dispatch_get_main_queue(), ^{
						  if (success) {
							  [Utils bundleIPA:self];
						  } else {
							  [Utils showError:self title:error error:nil];
						  }
					  });
				  }];

			break;
		}
		case 18: { // Restore IPA Patch
			NSFileManager* fm = [NSFileManager defaultManager];
			NSString* infoPath = [bundlePath URLByAppendingPathComponent:@"Info.plist"].path;
			NSString* infoBackupPath = [bundlePath URLByAppendingPathComponent:@"InfoBackup.plist"].path;
			if ([fm fileExistsAtPath:infoBackupPath]) {
				NSMutableDictionary* infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoBackupPath];
				[infoDict writeToFile:infoPath atomically:YES];
			} else {
				[Utils showError:self title:@"InfoBackup.plist missing!" error:nil];
				break;
			}
			[Patcher patchGDBinary:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"] to:[bundlePath URLByAppendingPathComponent:@"GeometryJump"]
				withHandlerAddress:0x8b8000
							 force:YES
					  withSafeMode:YES
				  withEntitlements:NO completionHandler:^(BOOL success, NSString* error) {
					  dispatch_async(dispatch_get_main_queue(), ^{
						  if (success) {
							  [Utils showNotice:self title:@"Binary restored and Info.plist restored! Launching should be safe now..."];
						  } else {
							  [Utils showError:self title:error error:nil];
						  }
					  });
				  }];

			break;
		}
		case 19: { // View Bundle Dir
			FileBrowserViewController* browser = [[FileBrowserViewController alloc] initWithPath:[[NSBundle mainBundle] bundlePath]];
			UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:browser];
			[self presentViewController:navController animated:YES completion:nil];
			break;
		}
		case 20: { // View Doc Dir
			FileBrowserViewController* browser = [[FileBrowserViewController alloc] init];
			UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:browser];
			[self presentViewController:navController animated:YES completion:nil];
			break;
		}
		case 21: // View NSUserDefaults
			[self.navigationController pushViewController:[[NSUDBrowserVC alloc] init] animated:YES];
			break;
		}
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// ios 13 bad!
- (void)switchValueChanged:(UISwitch*)sender {
	switch (sender.tag) {
	case 0: // Enable Automatic Updates
		[Utils toggleKey:@"UPDATE_AUTOMATICALLY"];
		break;
	case 1: // Automatically Launch
		[Utils toggleKey:@"LOAD_AUTOMATICALLY"];
		break;
	case 2: // Dev Mode
		[Utils toggleKey:@"DEVELOPER_MODE"];
		[self.tableView reloadData];
		break;
	case 3: // Use Tweak instead of JIT
		if ([sender isOn]) {
			[Utils showNotice:self title:@"advanced.use-tweak.warning".loc];
		}
		[Utils toggleKey:@"USE_TWEAK"];
		[self.tableView reloadData];
		break;
	case 4: // Auto JIT
		if ([sender isOn]) {
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"jit.enable-auto-jit.warning.title".loc message:@"jit.enable-auto-jit.warning".loc
																	preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"common.yes".loc style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction* _Nonnull action) { [[Utils getPrefs] setBool:YES forKey:@"AUTO_JIT"]; }];
			UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"common.no".loc style:UIAlertActionStyleDefault
															 handler:^(UIAlertAction* _Nonnull action) { [sender setOn:NO]; }];
			[alert addAction:yesAction];
			[alert addAction:noAction];
			[self presentViewController:alert animated:YES completion:nil];
		} else {
			[[Utils getPrefs] setBool:NO forKey:@"AUTO_JIT"];
		}
		break;
	case 5: // Rotate Fix
		[Utils toggleKey:@"FIX_ROTATION"];
		break;
	case 6: // Completed Setup
		[Utils toggleKey:@"CompletedSetup"];
		break;
	case 7:
		[Utils toggleKey:@"MANUAL_REOPEN"];
		break;
	case 8:
		[Utils toggleKey:@"FIX_BLACKSCREEN"];
		break;
	case 9: {
		[Utils toggleKey:@"JITLESS"];
		if ([sender isOn]) {
			[[Utils getPrefs] setBool:NO forKey:@"MANUAL_REOPEN"];
			[[UIApplication sharedApplication] setAlternateIconName:@"Pride" completionHandler:^(NSError* _Nullable error) {
				if (error) {
					AppLog(@"Failed to set alternate icon: %@", error);
				} else {
					AppLog(@"Icon set successfully.");
				}
			}];
		} else {
			NSFileManager* fm = [NSFileManager defaultManager];
			NSURL* bundlePath = [[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]];
			if (![fm fileExistsAtPath:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"].path]) {
				AppLog(@"Not restoring binary.");
			} else {
				NSError* err;
				[fm removeItemAtURL:[bundlePath URLByAppendingPathComponent:@"GeometryJump"] error:&err];
				if (err) {
					AppLog(@"Couldn't remove patched binary: %@", err);
				} else {
					[fm copyItemAtURL:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"] toURL:[bundlePath URLByAppendingPathComponent:@"GeometryJump"] error:&err];
					if (err) {
						AppLog(@"Couldn't copy binary: %@", err);
					} else {
						[[Utils getPrefs] setObject:@"NO" forKey:@"PATCH_CHECKSUM"];
						AppLog(@"Restored original binary.");
					}
				}
			}
		}
		[self.tableView reloadData];
		break;
	}
	case 10:
		break;
	case 11:
		[Utils toggleKey:@"USE_NIGHTLY"];
		break;
	case 12:
		if ([sender isOn]) {
			[Utils showNotice:self title:@"developer.webserver.msg".loc];
		}
		[Utils toggleKey:@"WEB_SERVER"];
		break;
	case 13:
		[Utils toggleKey:@"DONT_WARN_JIT"];
		break;
	case 14:
		[Utils toggleKey:@"FORCE_PATCHING"];
		break;
	case 15:
		[Utils toggleKey:@"DONT_PATCH_SAFEMODE"];
		break;
	case 16: {
		if ([sender isOn]) {
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"jitless.enterprise.warning".loc preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Yes I do" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* _Nonnull action) {
				[Utils toggleKey:@"ENTERPRISE_MODE"];
				[self.tableView reloadData];
			}];
			UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
			[alert addAction:okAction];
			[alert addAction:cancelAction];
			[self presentViewController:alert animated:YES completion:nil];
		} else {
			[Utils toggleKey:@"ENTERPRISE_MODE"];
			[[Utils getPrefs] setBool:NO forKey:@"IS_COMPRESSING_IPA"];
			[[Utils getPrefs] setObject:@"NO" forKey:@"PATCH_CHECKSUM"];
			NSFileManager* fm = [NSFileManager defaultManager];
			NSURL* dataPath = [[LCPath docPath] URLByAppendingPathComponent:@"shared"];
			[fm removeItemAtURL:dataPath error:nil];
			if ([fm fileExistsAtPath:[[fm temporaryDirectory] URLByAppendingPathComponent:@"tmp.zip"].path]) {
				[fm removeItemAtPath:[[fm temporaryDirectory] URLByAppendingPathComponent:@"tmp.zip"].path error:nil];
			}
			NSURL* bundlePath = [[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]];
			if (![fm fileExistsAtPath:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"].path]) {
				AppLog(@"Not restoring binary.");
			} else {
				NSError* err;
				[fm removeItemAtURL:[bundlePath URLByAppendingPathComponent:@"GeometryJump"] error:&err];
				if (err) {
					AppLog(@"Couldn't remove patched binary: %@", err);
				} else {
					[fm copyItemAtURL:[bundlePath URLByAppendingPathComponent:@"GeometryOriginal"] toURL:[bundlePath URLByAppendingPathComponent:@"GeometryJump"] error:&err];
					if (err) {
						AppLog(@"Couldn't copy binary: %@", err);
					} else {
						[[Utils getPrefs] setObject:@"NO" forKey:@"PATCH_CHECKSUM"];
						AppLog(@"Restored original binary.");
					}
				}
			}
			[fm removeItemAtPath:[[fm temporaryDirectory] URLByAppendingPathComponent:@"Helper.ipa"].path error:nil];
			NSString* infoPath = [bundlePath URLByAppendingPathComponent:@"Info.plist"].path;
			NSString* infoBackupPath = [bundlePath URLByAppendingPathComponent:@"InfoBackup.plist"].path;
			if ([fm fileExistsAtPath:infoBackupPath]) {
				NSMutableDictionary* infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoBackupPath];
				[infoDict writeToFile:infoPath atomically:YES];
				[Utils showNotice:self title:@"Restored."];
			} else {
				[Utils showError:self title:@"InfoBackup.plist missing!" error:nil];
			}
		}
		[self.tableView reloadData];
		break;
	}
	case 17:
		[Utils toggleKey:@"FORCE_ENTERPRISE"];
		[self.tableView reloadData];
		break;
	case 18:
		[Utils toggleKey:@"IS_COMPRESSING_IPA"];
		break;
	case 19:
		[Utils toggleKey:@"MANUAL_IMPORT_CERT"];
		[self.tableView reloadData];
		break;
	}
}

- (void)themeSelected:(UISegmentedControl*)sender {
	NSInteger style = sender.selectedSegmentIndex;
	[[Utils getPrefs] setInteger:style forKey:@"CURRENT_THEME"];

	UIWindow* keyWindow = nil;
	for (UIWindow* window in [UIApplication sharedApplication].windows) {
		if (window.isKeyWindow) {
			keyWindow = window;
			break;
		}
	}
	if (!keyWindow) {
		keyWindow = [UIApplication sharedApplication].windows.firstObject;
	}
	if (keyWindow) {
		switch (style) {
		case 0: // System
			keyWindow.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
			break;
		case 1: // Light
			keyWindow.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
			break;
		case 2: // Dark
			keyWindow.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
			break;
		}
		keyWindow.backgroundColor = [Theming getBackgroundColor];
		[self.root refreshTheme];
		[self.tableView reloadData];
	}
}

#pragma mark - Text Field Delegate
- (void)textFieldDidEndEditing:(UITextField*)textField {
	switch (textField.tag) {
	case 0: // address
		[[Utils getPrefs] setValue:textField.text forKey:@"SideJITServerAddr"];
		break;
	case 1: // udid
		[[Utils getPrefs] setValue:textField.text forKey:@"JITDeviceUDID"];
		break;
	case 2: // reinstall addr
		[[Utils getPrefs] setValue:textField.text forKey:@"DEV_REINSTALL_ADDR"];
		break;
	case 3: // launch args
		[[Utils getPrefs] setValue:textField.text forKey:@"LAUNCH_ARGS"];
		break;
	case 4: // nightly date
		[[Utils getPrefs] setValue:textField.text forKey:@"NIGHTLY_DATE"];
		break;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)ms_dismissViewController:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MSColorViewDelegate

- (void)colorViewController:(MSColorSelectionViewController*)colorViewCntroller didChangeColor:(UIColor*)color {
	[Theming saveAccentColor:color];
	[self.root updateState];
	[self.tableView reloadData];
	//[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Document Delegate Funcs (for importing cert mainly)
- (void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentAtURL:(NSURL*)url {
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentsAtURLs:(nonnull NSArray<NSURL*>*)urls {
	if (_isImportCert) {
		_isImportCert = NO;
		if (urls.count != 1)
			return [Utils showError:self title:@"You must select a p12 certificate!" error:nil];
		AppLog(@"Selected URLs: %@", urls);
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Input the password of the Certificate." message:@"This will be used for signing."
																preferredStyle:UIAlertControllerStyleAlert];
		[alert addTextFieldWithConfigurationHandler:^(UITextField* _Nonnull textField) {
			textField.placeholder = @"Certificate Password";
			textField.secureTextEntry = YES;
		}];
		UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* _Nonnull action) {
			UITextField* field = alert.textFields.firstObject;
			[self certPass:field.text url:urls.firstObject];
		}];

		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		[alert addAction:okAction];
		[alert addAction:cancelAction];
		[self presentViewController:alert animated:YES completion:nil];
	} else if (_isImportIPA) {
		_isImportIPA = NO;
		NSURL* url = urls.firstObject;
		if (url) {
			[self dismissViewControllerAnimated:YES completion:nil];
			dispatch_async(dispatch_get_main_queue(), ^{
				AppLog(@"start installing ipa!");
				_root.optionalTextLabel.text = @"launcher.status.extracting".loc;
				[_root progressCancelVisibility:NO];
			});
			[VerifyInstall startGDInstall:_root url:url];
		}
	}
}

- (void)certPass:(NSString*)certPass url:(NSURL*)url {
	NSError* err;
	NSData* certData = [NSData dataWithContentsOfURL:url options:0 error:&err];
	if (err) {
		[Utils showError:self title:@"jitless.cert.readerror".loc error:err];
		return;
	}
	NSString* teamId = [LCUtils getCertTeamIdWithKeyData:certData password:certPass];
	if (!teamId) {
		[Utils showError:self title:@"jitless.cert.invalidcert".loc error:nil];
		return;
	}

	AppLog(@"Import complete!");
	NSUserDefaults* NSUD = [Utils getPrefs];
	[NSUD setObject:certPass forKey:@"LCCertificatePassword"];
	[NSUD setObject:certData forKey:@"LCCertificateData"];
	[NSUD setBool:YES forKey:@"LCCertificateImported"];
	if (![Utils isDevCert]) {
		[Utils showNotice:self title:@"jitless.cert.dev-cert".loc];
	} else {
		[Utils showNotice:self title:@"jitless.cert.success".loc];
	}
	[self.tableView reloadData];
}
@end
