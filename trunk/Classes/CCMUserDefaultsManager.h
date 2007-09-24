
#import <Cocoa/Cocoa.h>


@interface CCMUserDefaultsManager : NSObject 
{
	NSUserDefaults	*userDefaults;
}

- (int)pollInterval;

- (void)addProject:(NSString *)projectName onServerWithURL:(NSString *)serverUrl;
- (BOOL)projectListContainsProject:(NSString *)projectName onServerWithURL:(NSString *)serverUrl;
- (NSArray *)projectListEntries;
- (NSArray *)servers;

- (void)addServerURLToHistory:(NSString *)serverUrl;
- (NSArray *)serverURLHistory;

@end


extern NSString *CCMDefaultsPollIntervalKey;

extern NSString *CCMDefaultsProjectListKey;
extern NSString *CCMDefaultsProjectEntryNameKey;
extern NSString *CCMDefaultsProjectEntryServerUrlKey;

extern NSString *CCMDefaultsServerUrlHistoryKey;
