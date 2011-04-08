
#import "CCMProjectTest.h"
#import "CCMProject.h"

@implementation CCMProjectTest

- (void)testCanCallMethodsForInfoKeys
{
	CCMProject *project = [[[CCMProject alloc] initWithName:@"connectfour"] autorelease];
	NSDictionary *info = [NSDictionary dictionaryWithObject:@"Success" forKey:@"lastBuildStatus"];
	[project updateWithInfo:info];
	
	STAssertEquals(@"Success", [project lastBuildStatus], @"Should have returned right build status.");
}

- (void)testRaisesUnknownMethodExceptionForMethodsNotCorrespondingToInfoKeys
{
	CCMProject *project = [[[CCMProject alloc] initWithName:@"connectfour"] autorelease];
	NSDictionary *info = [NSDictionary dictionaryWithObject:@"Success" forKey:@"lastBuildStatus"];
	[project updateWithInfo:info];
	
	STAssertThrows([(id)project lowercaseString], @"Should have thrown an exception.");
}

- (void)testImplementsKeyValueCoding
{
	CCMProject *project = [[[CCMProject alloc] initWithName:@"connectfour"] autorelease];
	NSDictionary *info = [NSDictionary dictionaryWithObject:@"Success" forKey:@"lastBuildStatus"];
	[project updateWithInfo:info];
	
	STAssertEquals(@"connectfour", [project valueForKey:@"name"], @"Should have returned right project name.");
	STAssertEquals(@"Success", [project valueForKey:@"lastBuildStatus"], @"Should have returned right build status.");
}

- (void)testParsesFailedStatusString
{
	CCMProject *project = [[[CCMProject alloc] initWithName:@"connectfour"] autorelease];
	NSDictionary *info = [NSDictionary dictionaryWithObject:CCMFailedStatus forKey:@"lastBuildStatus"];
	[project updateWithInfo:info];

	STAssertTrue([project isFailed], @"Should return YES.");
}

- (void)testParsesBuildingActivityString
{
	CCMProject *project = [[[CCMProject alloc] initWithName:@"connectfour"] autorelease];
	NSDictionary *info = [NSDictionary dictionaryWithObject:CCMBuildingActivity forKey:@"activity"];
	[project updateWithInfo:info];
	
	STAssertTrue([project isBuilding], @"Should return YES.");
}

@end
