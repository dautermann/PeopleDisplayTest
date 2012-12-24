//
//  MainPeopleViewController.h
//  PeopleDisplayTest
//
//  Created by Michael Dautermann on 12/18/12.
//  Copyright (c) 2012 Michael Dautermann. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void(^imageBlock)(NSImage * image);

@interface MainPeopleViewController : NSViewController <NSTableViewDataSource>
{
    NSArray * personArray;
    IBOutlet NSTableView * personTable;
}

@end
