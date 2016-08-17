//
//  main.m
//  todayview
//
//  Created by Andrew White on 8/16/16.
//  Copyright © 2016 Andrew White. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GBCli/GBCli.h>
@import EventKit;

NSString* formatCalenderEvent(EKEvent* event);

int main(int argc, char ** argv) {
    @autoreleasepool {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        EKEventStore *store = [[EKEventStore alloc] init];
        [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
            if(!granted){
                NSLog(@"Access to Calendar is necessary to use this program");
                exit(1);
            }
        }];
        
        //Command Line Argument Parsing
        GBSettings *factoryDefaults = [GBSettings settingsWithName:@"Factory" parent:nil];
        [factoryDefaults setInteger:0 forKey:@"daysFromNow"];
        GBSettings *settings = [GBSettings settingsWithName:@"CmdLine" parent:factoryDefaults];
        
        GBCommandLineParser *parser = [[GBCommandLineParser alloc] init];
        
        GBOptionsHelper *options = [[GBOptionsHelper alloc] init];
        [options registerOption:'d' long:@"daysFromNow" description:@"Which day to print, 0 is today" flags:GBOptionRequiredValue];
        [options registerOption:'h' long:@"help" description:@"Display this help and exit"
                                                    flags:GBOptionNoValue|GBOptionNoPrint];
        options.printHelpHeader = ^{ return @"Usage: todayview [-d days]"; };
        
        [parser registerSettings:settings];
        [parser registerOptions:options];
        [parser parseOptionsWithArguments:argv count:argc];
        
        if ([settings boolForKey:@"help"]) {
            [options printHelp];
            return 0;
        }
        
        
        // Create the start date components
        NSDate* date = NSDate.date;
        NSCalendarUnit preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
        NSDateComponents* components = [calendar components:preservedComponents fromDate:date];
        NSDate* normalizedToday = [calendar dateFromComponents:components];
        
        NSDateComponents *dayShift = [[NSDateComponents alloc] init];
        dayShift.day = [settings integerForKey:@"daysFromNow"];
        NSDate *startDate = [calendar dateByAddingComponents:dayShift
                                                    toDate:normalizedToday
                                                    options:0];

        // Create the end date components
        NSDateComponents *oneDay = [[NSDateComponents alloc] init];
        oneDay.day = 1;
        NSDate *oneDayFromStart = [calendar dateByAddingComponents:oneDay
                                                           toDate:startDate
                                                          options:0];
        
        // Create the predicate from the event store's instance method
        NSPredicate *predicate = [store predicateForEventsWithStartDate:startDate
                                                            endDate:oneDayFromStart
                                                            calendars:nil];
        
        // Fetch all events for the day
        NSArray *events = [store eventsMatchingPredicate:predicate];
        
        for (EKEvent* event in events) {
            NSLog(@"%@", formatCalenderEvent(event));
        }
    }
    return 0;
}

NSString* formatCalenderEvent(EKEvent* event){
    NSString* out = [[NSString alloc] init];
    out = [event title];
    
    //All Day Events
    if([event isAllDay]){
        out = [NSString stringWithFormat:@"(All Day) %@", out];
    }
    else{
        //Event Times
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"hh:mm"];
        
        NSString* startTime = [formatter stringFromDate:[event startDate]];
        NSString* endTime = [formatter stringFromDate:[event endDate]];
        out = [NSString stringWithFormat:@"%@ \t(%@-%@)", out, startTime, endTime];
    }
    
    //Locations
    if([[event location] length]!= 0){
        //Edit location to single line
        NSString* shortLoc = [[event location] componentsSeparatedByString:@"\n"][0];
        out = [NSString stringWithFormat:@"%@ \t[%@]", out, shortLoc];
    }
    return out;
}
