//
//  MainPeopleViewController.m
//  PeopleDisplayTest
//
//  Created by Michael Dautermann on 12/18/12.
//  Copyright (c) 2012 Michael Dautermann. All rights reserved.
//

#import "MainPeopleViewController.h"
#import "PersonObject.h"

@interface MainPeopleViewController ()

@end

void NSImageFromURL( NSURL * URL, void (^imageBlock)(NSURL * url, NSImage * image), void (^errorBlock)(void) )
{
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^(void)
                   {
                       // check the cache folder first to see if a file
                       // with this name exists...
                       NSArray * urlArray = [[NSFileManager defaultManager] URLsForDirectory: NSCachesDirectory inDomains:NSUserDomainMask];
                       if(urlArray)
                       {
                           NSURL * urlToCacheFolder = [urlArray objectAtIndex: 0];
                           NSURL * urlToPotentialCachedImage = [urlToCacheFolder URLByAppendingPathComponent: [URL lastPathComponent]];
                           NSData * data = [[NSData alloc] initWithContentsOfURL: urlToPotentialCachedImage];
                           if(data == NULL)
                           {
                               data = [[NSData alloc] initWithContentsOfURL:URL];
                               if(data)
                               {
                                   NSError * error = NULL;
                                   
                                   // now that we have the data, write it out to a cache file
                                   if([data writeToURL:urlToPotentialCachedImage options:NSAtomicWrite error:&error] == NO)
                                   {
                                       NSLog( @"error in writing to %@ - %@", [urlToPotentialCachedImage absoluteString], [error localizedDescription]);
                                   }
                               }
                           }
                           
                           if(data)
                           {
                               NSURL * someURL = NULL;
                               NSImage * image = [[NSImage alloc] initWithData:data];
                               dispatch_async( dispatch_get_main_queue(), ^(void){
                                   if( image != nil )
                                   {
                                       imageBlock(someURL, image);
                                   } else {
                                       errorBlock();
                                   }
                               });
                           }
                       }
                   });
}


@implementation MainPeopleViewController

// found this handy function at
// http://ios-blog.co.uk/tutorials/uiimage-from-url-–-simplified-using-blocks/
//
- (void) awakeFromNib
{
    // doing this insures that we only initialize the personArray ivar once...
    if(personArray == NULL)
    {
    // let's go get the data from the server
        NSError * error = NULL;
        NSXMLDocument * documentFromServer = [[NSXMLDocument alloc] initWithContentsOfURL: [NSURL URLWithString: @"http://dl.dropbox.com/u/2071896/People.xml"] options: NSXMLDocumentValidate error: &error];
        if(documentFromServer)
        {
            NSXMLElement * rootElement = [documentFromServer rootElement];
            if(rootElement)
            {
                NSInteger personCount = 0;
                NSArray * personArrayFromXML = [rootElement elementsForName: @"person"];
                NSLog( @"personArray has %ld elements", [personArrayFromXML count]);
                NSMutableArray * mutablePersonArray = [[NSMutableArray alloc] initWithCapacity: [personArrayFromXML count]];
                for(NSXMLElement * personElement in personArrayFromXML)
                {
                    PersonObject * newPerson = [[PersonObject alloc] init];
                    if(newPerson)
                    {
                        NSXMLElement * nameElement = NULL;
                        NSXMLElement * urlElement = NULL;
                        NSArray * elementArray = [personElement elementsForName: @"name"];
                        if([elementArray count] > 0)
                        {
                            nameElement = [elementArray objectAtIndex: 0];
                            if(nameElement)
                            {
                                NSLog( @"name is %@", [nameElement stringValue]);
                                newPerson.name = [nameElement stringValue];
                            }
                        }
                        
                        elementArray = [personElement elementsForName: @"url"];
                        if([elementArray count] > 0)
                        {
                            urlElement = [elementArray objectAtIndex: 0];
                            if(urlElement)
                            {
                                NSLog( @"url is %@", [urlElement stringValue]);
                                newPerson.urlToImage = [NSURL URLWithString: [urlElement stringValue]];
                                
                                NSImageFromURL(newPerson.urlToImage,^(NSURL * url, NSImage * image){
                                    newPerson.image = image;

                                    // reload the picture if the cell is visible
                                    [personTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:personCount] columnIndexes:[NSIndexSet indexSetWithIndex:0] ];
                                }, NULL);

                                personCount++;
                            }
                        }
                        
                        [mutablePersonArray addObject: newPerson];
                    }
                }
                
                // change mutable into immutable...
                //
                // we may be able to get away with just assigning the mutable into a immutable property.  Not sure yet.
                if([mutablePersonArray count] > 0)
                {
                    personArray = [[NSArray alloc] initWithArray: mutablePersonArray];
                }
            }
        } else {
            NSLog( @"error while retrieving XML document - %@", [error localizedDescription]);
        }
        
        [personTable reloadData];
    }
}

#pragma mark table view data source methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(personArray)
        return([personArray count]);
    else
        return 0;
}

- (id)tableView: (NSTableView *) aTableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSView * viewAsTableCell = [aTableView makeViewWithIdentifier: @"PersonView" owner: self];
    PersonObject * pObject = [personArray objectAtIndex: row];
    
    if(viewAsTableCell)
    {
        NSTextField * nameField =  (NSTextField * )[viewAsTableCell viewWithTag: 1];
        nameField.stringValue = pObject.name;
        
        NSImageView * personImageView = (NSImageView *) [viewAsTableCell viewWithTag: 2];
        personImageView.image = pObject.image;

    }
    return(viewAsTableCell);
}

@end
