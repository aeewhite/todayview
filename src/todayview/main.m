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

NSString* formatCalenderEvent(EKEvent* event, GBSettings* settings);

int main(int argc, char ** argv) {
    @autoreleasepool {
        //Command Line Argument Parsing
        GBSettings *factoryDefaults = [GBSettings settingsWithName:@"Factory" parent:nil];
        [factoryDefaults setInteger:0 forKey:@"daysFromNow"];
        [factoryDefaults setBool:false forKey:@"period"];
        GBSettings *settings = [GBSettings settingsWithName:@"CmdLine" parent:factoryDefaults];
        
        GBCommandLineParser *parser = [[GBCommandLineParser alloc] init];
        
        GBOptionsHelper *options = [[GBOptionsHelper alloc] init];
        [options registerOption:'d' long:@"daysFromNow" description:@"Which day to print, 0 is today" flags:GBOptionRequiredValue];
        [options registerOption:'p' long:@"period" description:@"Display period (AM/PM)" flags:GBOptionNoValue];
        [options registerOption:'h' long:@"help" description:@"Display this help and exit"
                                                    flags:GBOptionNoValue|GBOptionNoPrint];
        options.printHelpHeader = ^{ return @"Usage: todayview [-d days] [-p]"; };
        
        [parser registerSettings:settings];
        [parser registerOptions:options];
        [parser parseOptionsWithArguments:argv count:argc];
        
        if ([settings boolForKey:@"help"]) {
            [options printHelp];
            return 0;
        }
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        EKEventStore *store = [[EKEventStore alloc] init];
        [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
            if(!granted){
                NSLog(@"Access to Calendar is necessary to use this program");
                exit(1);
            }
        }];
        
        
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
            printf("%s\n", [formatCalenderEvent(event, settings) UTF8String]);
        }
    }
    return 0;
}

NSString* formatCalenderEvent(EKEvent* event, GBSettings* settings){
    NSString* out = [[NSString alloc] init];
    out = [event title];
    
    //All Day Events
    if([event isAllDay]){
        //Extra padding for AM/PM
        if([settings boolForKey:@"period"]){
            out = [NSString stringWithFormat:@"(All Day)         \t %@", out];
        }
        else{
            out = [NSString stringWithFormat:@"(All Day)     \t %@", out];
        }
    }
    else{
        //Event Times
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        if([settings boolForKey:@"period"]){
            [formatter setDateFormat:@"hh:mma"];
        }
        else{
            [formatter setDateFormat:@"hh:mm"];
        }
        
        NSString* startTime = [formatter stringFromDate:[event startDate]];
        NSString* endTime = [formatter stringFromDate:[event endDate]];
        
        out = [NSString stringWithFormat:@"(%@-%@)\t %@", startTime, endTime, out];
    }
    
    //Locations
    if([[event location] length]!= 0){
        //Edit location to single line
        NSString* shortLoc = [[event location] componentsSeparatedByString:@"\n"][0];
        out = [NSString stringWithFormat:@"%@ \t[%@]", out, shortLoc];
    }
    return out;
}
