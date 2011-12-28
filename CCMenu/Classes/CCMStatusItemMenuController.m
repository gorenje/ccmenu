
#import <EDCommon/EDCommon.h>
#import "CCMStatusItemMenuController.h"
#import "CCMImageFactory.h"
#import "CCMServerMonitor.h"
#import "CCMProject.h"

@implementation CCMStatusItemMenuController

- (void)setMenu:(NSMenu *)aMenu
{
	statusMenu = aMenu;
}

- (void)setImageFactory:(CCMImageFactory *)anImageFactory
{
	[imageFactory autorelease];
	imageFactory = [anImageFactory retain];
}

- (void)awakeFromNib
{
	[self createStatusItem];
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(statusUpdate:) name:CCMProjectStatusUpdateNotification object:nil];
}

- (NSStatusItem *)createStatusItem
{
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];	
	[statusItem setImage:[imageFactory imageForUnavailableServer]];
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:statusMenu];
	return statusItem;
}

- (void)displayProjects:(NSArray *)projectList
{
	NSMenu *menu = [statusItem menu];
	
	int index = 0;
	while([[[menu itemArray] objectAtIndex:index] isSeparatorItem] == FALSE)
		[menu removeItemAtIndex:index];
	
	unsigned failSleepingCount = 0;
	unsigned failBuildingCount = 0;
	unsigned successSleepingCount = 0;
	unsigned successBuildingCount = 0;
	bool haveAtLeastOneStatus = NO;
    for(CCMProject *project in [projectList sortedArrayByComparingAttribute:@"name"])
	{
		NSString *title = [NSString stringWithFormat:@"%@", [project name]];
		NSMenuItem *menuItem = [menu insertItemWithTitle:title action:@selector(openProject:) keyEquivalent:@"" atIndex:index++];
		NSImage *image = [imageFactory imageForActivity:[project activity] lastBuildStatus:[project lastBuildStatus]];
		image = [imageFactory convertForMenuUse:image];
		[menuItem setImage:image];
		BOOL isFailed = [project isFailed];
		BOOL isBuilding = [project isBuilding];
		if (isFailed && isBuilding)
			failBuildingCount += 1;
		else if (isFailed && !isBuilding)
			failSleepingCount += 1;
		else if (!isFailed && isBuilding)
			successBuildingCount += 1;
		else 
			successSleepingCount += 1;

		if([project lastBuildStatus] != nil)
			haveAtLeastOneStatus = YES;

		[menuItem setTarget:self];
		[menuItem setRepresentedObject:project];
	}
	if(haveAtLeastOneStatus == NO)
	{
		[statusItem setImage:[imageFactory imageForActivity:nil lastBuildStatus:nil]];
		[statusItem setTitle:@""];
	}
	else if(failSleepingCount > 0)
	{
		[statusItem setImage:[imageFactory imageForActivity:CCMSleepingActivity lastBuildStatus:CCMFailedStatus]];
		[statusItem setTitle:[NSString stringWithFormat:@"%u", failSleepingCount + failBuildingCount]];
	}
	else if(failBuildingCount > 0)
	{
		[statusItem setImage:[imageFactory imageForActivity:CCMBuildingActivity lastBuildStatus:CCMFailedStatus]];
		[statusItem setTitle:[NSString stringWithFormat:@"%u", failBuildingCount]];
	}
	else if (successBuildingCount > 0)
	{
		[statusItem setImage:[imageFactory imageForActivity:CCMBuildingActivity lastBuildStatus:CCMSuccessStatus]];
		[statusItem setTitle:@""];
	}
	else
	{
		[statusItem setImage:[imageFactory imageForActivity:CCMSleepingActivity lastBuildStatus:CCMSuccessStatus]];
		[statusItem setTitle:@""];
	}
}

- (void)statusUpdate:(NSNotification *)notification
{	
	[self displayProjects:[[notification object] projects]];
}

- (IBAction)openProject:(id)sender
{
	NSString *urlString = [[sender representedObject] webUrl];
	if(urlString == nil)
	{
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		NSString *errorString = [[sender representedObject] valueForKey:@"errorString"];
		if(errorString != nil) 
		{
			[alert setMessageText:NSLocalizedString(@"An error occured when retrieving the project status", "Alert message when an error occured talking to the server.")];
			[alert setInformativeText:errorString];
		}
		else
		{
			[alert setMessageText:NSLocalizedString(@"Cannot open web page", "Alert message when server does not provide webUrl")];
			[alert setInformativeText:NSLocalizedString(@"This continuous integration server does not provide web URLs for projects. Please contact the server administrator.", "Informative text when server does not provide webUrl")];
		}
		[alert runModal];
		return;
	}
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

@end
