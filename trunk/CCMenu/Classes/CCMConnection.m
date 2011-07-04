
#import "CCMConnection.h"
#import "CCMServerStatusReader.h"


@implementation CCMConnection

- (id)initWithURL:(NSURL *)theServerUrl
{
	[super init];
	serverUrl = [theServerUrl retain];
	return self;
}

- (id)initWithURLString:(NSString *)theServerUrlAsString
{
	return [self initWithURL:[NSURL URLWithString:theServerUrlAsString]];
}

- (void)dealloc
{
	[serverUrl release];
	[super dealloc];
}

- (void)setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (id)delegate
{
	return delegate;
}

- (NSString *)errorStringForError:(NSError *)error
{
	return [NSString stringWithFormat:@"Failed to get status from %@: %@",   
		[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey], [error localizedDescription]];
}

- (NSString *)errorStringForResponse:(NSHTTPURLResponse *)response
{
	return [NSString stringWithFormat:@"Failed to get status from %@: %@",   
			[response URL], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]]];
}

- (NSString *)errorStringForParseError:(NSError *)error
{
	return [NSString stringWithFormat:@"Failed to parse status from %@: %@ (Maybe the server is returning a temporary HTML error page instead of an XML document.)",   
                [serverUrl description], [[error localizedDescription] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (BOOL)testConnection
{
	NSURLRequest *request = [NSURLRequest requestWithURL:serverUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if(error != nil)
		[NSException raise:@"ConnectionException" format:@"%@", [self errorStringForError:error]];
	int status = [response statusCode];
	return (status >= 200 && status != 404 && status < 500);
}

- (NSArray *)retrieveServerStatus
{
	NSURLRequest *request = [NSURLRequest requestWithURL:serverUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if(error != nil)
		[NSException raise:@"ConnectionException" format:@"%@", [self errorStringForError:error]];
	if([response statusCode] != 200)
		[NSException raise:@"ConnectionException" format:@"%@", [self errorStringForResponse:response]];
	CCMServerStatusReader *reader = [[[CCMServerStatusReader alloc] initWithServerResponse:data] autorelease];
	return [reader projectInfos];
}

- (void)requestServerStatus
{
	if(urlConnection != nil)
		return;
	NSURLRequest *request = [NSURLRequest requestWithURL:serverUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	if((urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self]) == nil) 
		[NSException raise:@"ConfigurationException" format:@"Cannot create connection for URL [%@]", [serverUrl absoluteString]];	
	receivedData = [[NSMutableData data] retain];
}

- (void)cleanUpAfterStatusRequest
{
	[urlConnection release];
    [receivedData release];
	urlConnection = nil;
	receivedData = nil;
}

- (void)cancelStatusRequest
{
	if(urlConnection == nil)
		return;
	[urlConnection cancel];
	[self cleanUpAfterStatusRequest];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// this could be called multiple times, due to redirects for example, so we reset data
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	CCMServerStatusReader *reader = [[[CCMServerStatusReader alloc] initWithServerResponse:receivedData] autorelease];
    [self cleanUpAfterStatusRequest];
    NSError *error = [reader tryParse];
    if(error != nil)
        [delegate connection:self hadTemporaryError:[self errorStringForParseError:error]];
    else
        [delegate connection:self didReceiveServerStatus:[reader projectInfos]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self cleanUpAfterStatusRequest];
	[delegate connection:self hadTemporaryError:[self errorStringForError:error]];
}

@end
