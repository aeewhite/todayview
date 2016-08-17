//
//  main.m
//  todayview
//
//  Created by Andrew White on 8/16/16.
//  Copyright © 2016 Andrew White. All rights reserved.
//

#import <Foundation/Foundation.h>
@import EventKit;

NSString* printCalenderEvent(EKEvent* event);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        EKEventStore *store = [[EKEventStore alloc] init];
        [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
            if(granted){
                NSLog(@"Access granted");
            }
            else{
                NSLog(@"Access to Calendar is necessary to use this program");
                exit(1);
            }
        }];
        
        // insert code here...
        NSLog(@"Hello, World!");
        // Create the start date components
        NSDateComponents *oneDayAgoComponents = [[NSDateComponents alloc] init];
        oneDayAgoComponents.day = -1;
        NSDate *oneDayAgo = [calendar dateByAddingComponents:oneDayAgoComponents
                                                      toDate:[NSDate date]
                                                     options:0];
        
        // Create the end date components
        NSDateComponents *oneDayFromNowComponents = [[NSDateComponents alloc] init];
        oneDayFromNowComponents.day = 1;
        NSDate *oneDayFromNow = [calendar dateByAddingComponents:oneDayFromNowComponents
                                                           toDate:[NSDate date]
                                                          options:0];
        
        // Create the predicate from the event store's instance method
        NSPredicate *predicate = [store predicateForEventsWithStartDate:oneDayAgo
                                                                endDate:oneDayFromNow
                                                              calendars:nil];
        
        // Fetch all events that match the predicate
        NSArray *events = [store eventsMatchingPredicate:predicate];
        
        for (EKEvent* event in events) {
            NSLog(printCalenderEvent(event));
        }
    }
    return 0;
}

NSString* printCalenderEvent(EKEvent* event){
    NSString* out = [[NSString alloc] init];
    out = [event title];
    if([event isAllDay]){
        out = [NSString stringWithFormat:@"(All Day) %@", out];
    }
    return out;
}
