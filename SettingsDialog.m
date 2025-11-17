//
//  SettingsDialog.m
//  Svátek
//
//  Created by Mirek Novak on 20.03.2023.
//

#import "SettingsDialog.h"

@interface SettingsDialog ()

@end

/// <#Description#>
@implementation SettingsDialog {

    
    
}

- (NSArray *) names {
    if(!_names){
        [self setUpData];
    }
    return _names;
}

- (NSArray *) days {
    if(!_days){
        [self setUpData];
    }
    return _days;
}

- (NSArray *) hilites {
    if(!_hilites){
        [self setUpData];
    }
    return _hilites;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [_nameDaysTableView setDelegate:self];
    NSLog(@"WTF: %@", [self nameDays]);
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    for (NSTableColumn *tableColumn in self.nameDaysTableView.tableColumns ) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:tableColumn.identifier ascending:NO selector:@selector(compare:)];
        [tableColumn setSortDescriptorPrototype:sortDescriptor];
    }
}

-(void)setUpData{
    NSMutableArray *newNames = [[NSMutableArray alloc] initWithCapacity:[[self nameDays] count]];
    NSMutableArray *newDates = [[NSMutableArray alloc] initWithCapacity:[[self nameDays] count]];
    NSMutableArray *newHilites = [[NSMutableArray alloc] initWithCapacity:[[self nameDays] count]];
    NSArray *objects;
   // NSArray *keys;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd"];
    NSDateFormatter *dt = [[NSDateFormatter alloc] init];
    [dt setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"cs_CZ"]];
    [dt setDateFormat:@"d. MMMM"];
    
    objects = [[self nameDays] allValues];
    for (NSDictionary *row in objects) {
        [newNames addObject:[row objectForKey:@"name"]];
        NSDate *intermediate = [df dateFromString:[row objectForKey:@"date"]];
        NSString *interimString = [dt stringFromDate:intermediate];
        [newDates addObject: interimString];
        [newHilites addObject:[row objectForKey:@"hilite"]];
    }
    
    _names = [[NSArray alloc] initWithArray:newNames];
    _days = [[NSArray alloc] initWithArray:newDates];
    _hilites = [[NSArray alloc] initWithArray:newHilites];
    
}

-(void)windowWillClose:(NSNotification *)notification{
    NSLog(@"Closing window ...");
    [NSApp stopModal];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return  [[self nameDays] count];
    
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    
    NSString *ident = [tableColumn identifier];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:ident owner:self];
    
    if([ident isEqualToString:@"name"]){
        cell.textField.stringValue = [self.names objectAtIndex:row];
    }else
    if([ident isEqualToString:@"date"]){
        cell.textField.stringValue = [self.days objectAtIndex:row];
    }else{
        cell.textField.integerValue = [[self.hilites objectAtIndex:row] integerValue];
    }
    return cell;
}

//- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
//{
//    self.data = [self.data sortedArrayUsingDescriptors:sortDescriptors];
//    [aTableView reloadData];
//}
@end
