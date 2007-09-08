
#import "CCMAppController.h"
#import "CCMGrowlAdaptor.h"
#import "CCMBuildNotificationFactory.h"
#import "CCMBuildStatusTransformer.h"
#import "CCMTimeSinceDateTransformer.h"


@implementation CCMAppController

- (void)setupRequestCache
{
	NSURLCache *cache = [NSURLCache sharedURLCache];
	[cache setDiskCapacity:0];
	[cache setMemoryCapacity:2*1024*1024];
}

- (void)registerValueTransformers
{
	CCMBuildStatusTransformer *statusTransformer = [[[CCMBuildStatusTransformer alloc] init] autorelease];
	[statusTransformer setImageFactory:imageFactory];
	[NSValueTransformer setValueTransformer:statusTransformer forName:CCMBuildStatusTransformerName];
	
	CCMTimeSinceDateTransformer *dateTransformer = [[[CCMTimeSinceDateTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:dateTransformer forName:CCMTimeSinceDateTransformerName];
}

- (void)startGrowlAdaptor
{
	[growlAdaptor start]; 
}

- (void)startServerMonitor
{
	[serverMonitor setNotificationCenter:[NSNotificationCenter defaultCenter]];
	[serverMonitor setNotificationFactory:[[[CCMBuildNotificationFactory alloc] init] autorelease]];
	[serverMonitor start];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	@try
	{
		[self setupRequestCache];
		[self registerValueTransformers];
		[self startGrowlAdaptor];
		[self startServerMonitor];
		if([[serverMonitor projects] count] == 0)
			[preferencesController showWindow:self];
	}
	@catch(NSException *e)
	{
		// ignore; if we don't the run-loop might not get set up properly
	}
}

@end
