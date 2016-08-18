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

#define ANSI_BOLD          "\x1b[1m"
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_RESET   "\x1b[0m"


NSString* formatCalenderEvent(EKEvent* event, GBSettings* settings);



int main(int argc, char ** argv) {
    @autoreleasepool {
        //Command Line Argument Parsing
        GBSettings *factoryDefaults = [GBSettings settingsWithName:@"Factory" parent:nil];
        [factoryDefaults setInteger:0 forKey:@"daysFromNow"];
        [factoryDefaults setBool:false forKey:@"period"];
        [factoryDefaults setBool:false forKey:@"color"];
        GBSettings *settings = [GBSettings settingsWithName:@"CmdLine" parent:factoryDefaults];
        
        GBCommandLineParser *parser = [[GBCommandLineParser alloc] init];
        
        GBOptionsHelper *options = [[GBOptionsHelper alloc] init];
        [options registerOption:'d' long:@"daysFromNow" description:@"Which day to print, 0 is today" flags:GBOptionRequiredValue];
        [options registerOption:'p' long:@"period" description:@"Display period (AM/PM)" flags:GBOptionNoValue];
        [options registerOption:'c' long:@"color" description:@"Colorize output" flags:GBOptionNoValue];
        [options registerOption:'v' long:@"values" description:@"print input values" flags:GBOptionNoValue];
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
        if ([settings boolForKey:@"values"]) {
            [options printValuesFromSettings:settings];
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
    
    NSMutableArray* stringArray = [NSMutableArray arrayWithCapacity:9];
    
    //Times
    if([settings boolForKey:@"color"]){
        [stringArray addObject: [NSString stringWithFormat:@"%s",ANSI_COLOR_GREEN]];
    }
    if([event isAllDay]){
        //Extra padding for AM/PM
        if([settings boolForKey:@"period"]){
            [stringArray addObject:[NSString stringWithFormat:@"(All Day)         \t"]];
        }
        else{
           [stringArray addObject: [NSString stringWithFormat:@"(All Day)     \t"]];
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
        
        [stringArray addObject: [NSString stringWithFormat:@"(%@-%@)\t", startTime, endTime]];
    }
    if([settings boolForKey:@"color"]){
        [stringArray addObject: [NSString stringWithFormat:@"%s", ANSI_COLOR_RESET]];
    }
    
    //Event Name
    if([settings boolForKey:@"color"]){
        [stringArray addObject: [NSString stringWithFormat:@"%s%s",ANSI_COLOR_CYAN, ANSI_BOLD]];
    }
    [stringArray addObject:[event title]];
    if([settings boolForKey:@"color"]){
        [stringArray addObject: [NSString stringWithFormat:@"%s", ANSI_COLOR_RESET]];
    }
    

    //Locations
    if([settings boolForKey:@"color"]){
        [stringArray addObject: [NSString stringWithFormat:@"%s",ANSI_COLOR_MAGENTA]];
    }
    if([[event location] length]!= 0){
        //Edit location to single line
        NSString* shortLoc = [[event location] componentsSeparatedByString:@"\n"][0];
        [stringArray addObject: [NSString stringWithFormat:@" \t[%@]", shortLoc]];
    }
    if([settings boolForKey:@"color"]){
        [stringArray addObject: [NSString stringWithFormat:@"%s", ANSI_COLOR_RESET]];
    }
    
    return [[stringArray valueForKey:@"description"] componentsJoinedByString:@" "];;
}
