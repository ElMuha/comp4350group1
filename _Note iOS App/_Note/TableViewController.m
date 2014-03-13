//
//  TableViewController.m
//  _Note
//
//  COMP 4350 - Software Development 2
//  Group 1: _Note
//

#import "TableViewController.h"
#import "AppDelegate.h"
#import "NoteEditorViewController.h"
#import "Note.h"
#import <DropboxSDK/DropboxSDK.h>

@interface TableViewController () <DBRestClientDelegate>{
    NSMutableArray *_objects;
}
@property (nonatomic, strong) DBRestClient *restClient;
@end

@implementation TableViewController

-(NSMutableArray*) notes
{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return app.notes;
}
- (void)awakeFromNib
{
    self.clearsSelectionOnViewWillAppear = NO;
    self.preferredContentSize = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void)viewDidAppear:(BOOL)animated {
    // Whenever this view controller appears, reload the table. This allows it to reflect any changes
    // made whilst editing notes.
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    //UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    //self.navigationItem.rightBarButtonItem = addButton;
    self.noteEditorViewController = (NoteEditorViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;

}
/*
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
*/
#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self notes].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId
                                                            forIndexPath:indexPath];
    
    Note *note = [self notes][indexPath.row];
    cell.textLabel.text = note.title;
    
    //change this if you have functionality for setting fonts
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

// Link to load list of notes from server
- (IBAction)viewNoteLink{
    
    int size;
    
    if (_titles == nil)
    {
        // HTTP request to server for list of notes
        NSString *urlString = @"https://localhost:5000/lists";
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        NSURLResponse *urlResponse = nil;
        NSError *error = nil;
        
        NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest
                                              returningResponse:&urlResponse
                                                          error:&error];
        
        if (data != nil)
        {
            // Receive note json list
            self.json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"%@", _json);
            NSLog(@"Received JSON data from server in method");
            
            // Get list of note titles from received json
            NSString *success = [NSString stringWithFormat:@"%@", [_json objectForKey:@"success"]];
            NSString *success_criteria = @"1";
            
            if ([success isEqualToString:success_criteria])
            {
                _titles = [_json objectForKey: @"note_titles"];
                NSLog(@"Parsed JSON note title data from server");
            }
            else
            {
                NSLog(@"Failed to parse JSON note title data from server");
            }
        }
        
    }
    
    if (_titles != nil)
    {
        // For each note in the list, get contents of notes
        size = [_titles count];
        NSString *baseURL = @"https://localhost:5000/view_note/";
    
        for (int i = 0; i < size; i++)
        {
            NSDictionary* title_name = [_titles objectAtIndex:i];
            NSString *name = [title_name objectForKey: @"Title"];
            
            NSString *urlString = [baseURL stringByAppendingString:name];
            
            NSLog(@"name = %@", name);
            NSLog(@"url = %@", urlString);
            
            NSURL *url = [NSURL URLWithString:urlString];
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
            NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
        }
    }
    
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        NSLog(@"Folder '%@' contains:", metadata.path);
        for (DBMetadata *file in metadata.contents) {
            NSLog(@"	%@", file.filename);
        }
    }
}

- (void)restClient:(DBRestClient *)client
loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *object = _objects[indexPath.row];
    self.
    self.noteEditorViewController.detailItem = object;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NoteEditorViewController *editor = (NoteEditorViewController*)segue.destinationViewController;
    
    if ([segue.identifier isEqualToString:@"Selected"]){
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        editor.note = [self notes][path.row];
    }
    if ([segue.identifier isEqualToString:@"AddNewNote"]){
        editor.note = [Note noteWithText:@" "];
        [[self notes] addObject:editor.note];
    }
}

#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
{
    NSLog(@"Authentication challenge received from connection.");
    
    if ([challenge previousFailureCount] == 0)
    {
        _authenticated = YES;
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        
    }
    else
    {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
    NSLog(@"Received response from server.");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Load json information into object
    self.json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSLog(@"%@", _json);
    NSLog(@"Received JSON data from server");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Parse through json for note content
    NSString *note_json = [_json objectForKey:@"note"];
    NSLog(@"Note JSON: %@", note_json);
    
    if (note_json != nil)
    {
        NSData *data = [note_json dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *note_dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        NSString *content = [note_dictionary objectForKey:@"content"];
        NSString *title = [note_dictionary objectForKey:@"title"];
        
        NSLog(@"Content: %@", content);
        NSLog(@"Title: %@", title);
        
        Note *new_note = [Note noteWithText: [NSString stringWithFormat:@"%@\n%@", title, content]];
        [self.notes addObject:new_note];
    }
    
    [self.tableView reloadData];
    
}


// We use this method is to accept an untrusted site which unfortunately we need to do, as our servers are self signed.
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

@end
