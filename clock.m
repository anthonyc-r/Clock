/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include "math.h"

const CGFloat WINDOW_SIZE = 175.0;
const CGFloat WINDOW_ORIGIN_X = 300.0;
const CGFloat WINDOW_ORIGIN_Y = 300.0;
const CGFloat HAND_WIDTH = 10.0;
const CGFloat HAND_HOUR_HEIGHT = 50.0;
const CGFloat HAND_MINUTE_HEIGHT = 70.0;
// How much the end of the hand goes beyond the middle as a fraction
const CGFloat HAND_EXTENSION = 0.05;
const CGFloat DEGREES_IN_RAD = 180.0;
const CGFloat DEGREES_IN_CIRCLE = 360.0;
const CGFloat DEGREES_OFFSET = 90;
const CGFloat DEGREES_PER_HOUR = 30;
const CGFloat DEGREES_PER_MINUTE = 6;

const int HOURS_IN_CLOCK = 12;
const int MINUTES_IN_HOUR = 60;
const int SECONDS_IN_MINUTE = 60;

NSString *const DEFAULT_ORIGIN_X_KEY = @"clock_default_origin_x";
NSString *const DEFAULT_ORIGIN_Y_KEY = @"clock_default_origin_y";
NSString *const TITLE = @"Clock";
NSString *const BACKGROUND_NAME = @"clock_background_thin_small";


@interface ClockHandView: NSView {
@private
	CGFloat rotation;
}
- (void) setHandRotationToDegrees: (CGFloat)angle;
@end

@implementation ClockHandView

- (id) init {
	if ((self = [super init])) {
		rotation = 0;
	}
	return self;
}

- (void) drawRect: (NSRect) rect {
	CGFloat offsetRotation = DEGREES_OFFSET - rotation;
	CGFloat rads = (offsetRotation / DEGREES_IN_RAD) * M_PI;
	CGFloat height = rect.size.height / 2;
	CGFloat offsetX = rect.origin.x + rect.size.width / 2;
	CGFloat offsetY = rect.origin.y + rect.size.height / 2;
	CGFloat halfHandWidth = HAND_WIDTH / 2;
	NSPoint pointOne = NSMakePoint(height * cos(rads) + offsetX,
								   height * sin(rads) + offsetY);
	NSPoint pointTwo = NSMakePoint(halfHandWidth * cos(rads + M_PI_2) + offsetX,
								   halfHandWidth * sin(rads + M_PI_2) + offsetY);
	NSPoint pointThree = NSMakePoint(halfHandWidth * cos(rads - M_PI_2) + offsetX,
									 halfHandWidth* sin(rads - M_PI_2) + offsetY);
	CGFloat dx = pointOne.x - offsetX;
	CGFloat dy = pointOne.y - offsetY;
	pointTwo.x -= dx * HAND_EXTENSION;
	pointTwo.y -= dy * HAND_EXTENSION;
	pointThree.x -= dx * HAND_EXTENSION;
	pointThree.y -= dy * HAND_EXTENSION;
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint: pointOne];
	[path lineToPoint: pointThree];
	[path lineToPoint: pointTwo];
	[path closePath];
	[path fill];
}

- (void) setHandRotationToDegrees: (CGFloat)angle {
	rotation = angle;
}

@end

@interface ClockWindow: NSWindow<NSWindowDelegate> {
@private
	NSImageView *_background;
	ClockHandView *_hourHand;
	ClockHandView *_minuteHand;
	NSTimer *_timer;
}

- (void) updateTime;
- (void) setTimeToHours: (int)h minutes: (int)m seconds: (int)s;
+ (NSPoint) getDefaultOrigin;

@end

@implementation ClockWindow
	
- (id) init {
	NSPoint origin = [ClockWindow getDefaultOrigin];
	self = [super initWithContentRect: NSMakeRect(origin.x,
												  origin.y, 
												  WINDOW_SIZE, 
												  WINDOW_SIZE)
					        styleMask: NSTitledWindowMask | 
					   			  	   NSClosableWindowMask | 
								       NSMiniaturizableWindowMask
					          backing: NSBackingStoreRetained 
					            defer: false];
	if (self) {
		[self setTitle: TITLE];
		[self setDelegate: self];
		_background = [[NSImageView alloc] init];
		NSImage *backgroundImage = [NSImage imageNamed: BACKGROUND_NAME];
		if (!backgroundImage)
		   NSLog(@"Could not find background image resource");
		[backgroundImage setSize: NSMakeSize(WINDOW_SIZE, WINDOW_SIZE)];
		[_background setImage: backgroundImage];
		[_background setFrame: NSMakeRect(0, 0, WINDOW_SIZE, WINDOW_SIZE)];

		_hourHand =  [[ClockHandView alloc] init];
		[_hourHand setFrame: NSMakeRect(WINDOW_SIZE / 2 - HAND_HOUR_HEIGHT,
										WINDOW_SIZE / 2 - HAND_HOUR_HEIGHT,
										HAND_HOUR_HEIGHT * 2,
										HAND_HOUR_HEIGHT * 2)];
		_minuteHand = [[ClockHandView alloc] init];
		[_minuteHand setFrame: NSMakeRect(WINDOW_SIZE / 2 - HAND_MINUTE_HEIGHT,
										  WINDOW_SIZE / 2 - HAND_MINUTE_HEIGHT,
										  HAND_MINUTE_HEIGHT * 2, 
										  HAND_MINUTE_HEIGHT * 2)];
									  
		NSView *contentView = [self contentView];
		[contentView addSubview: _background];
		[contentView addSubview: _hourHand];
		[contentView addSubview: _minuteHand];
		
		_timer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(updateTime) userInfo: nil repeats: YES]; 
		[self updateTime];
	}

	return self;
}

- (void) close {
	[super close];
	[NSApp terminate: self];
}

- (void) updateTime {
	NSCalendarDate *date = [NSCalendarDate calendarDate];
	[self setTimeToHours: [date hourOfDay]
				 minutes: [date minuteOfHour]
				 seconds: [date secondOfMinute]];
}

- (void) setTimeToHours: (int)h minutes: (int)m seconds: (int)s {
	CGFloat hourRotation = 0;
	CGFloat minuteRotation = 0;
	CGFloat secondRotation = 0;
	
	secondRotation = DEGREES_IN_CIRCLE * ((CGFloat)s / SECONDS_IN_MINUTE);
	minuteRotation = DEGREES_IN_CIRCLE * ((CGFloat)m / MINUTES_IN_HOUR) +
					 (secondRotation * DEGREES_PER_MINUTE) / DEGREES_IN_CIRCLE;
					
	hourRotation = DEGREES_IN_CIRCLE * ((CGFloat)h / HOURS_IN_CLOCK) + 
				   (minuteRotation * DEGREES_PER_HOUR) / DEGREES_IN_CIRCLE;

	[_minuteHand setHandRotationToDegrees: minuteRotation];
	[_hourHand setHandRotationToDegrees: hourRotation];
	[_minuteHand setNeedsDisplay: YES];
	[_hourHand setNeedsDisplay: YES];
}

- (void) windowDidMove: (NSNotification*)aNotification {
	NSLog(@"Window did move!!");
	NSPoint newOrigin = [self frame].origin;
	[[NSUserDefaults standardUserDefaults] setFloat: newOrigin.x forKey: DEFAULT_ORIGIN_X_KEY];
	[[NSUserDefaults standardUserDefaults] setFloat: newOrigin.y forKey: DEFAULT_ORIGIN_Y_KEY];
}

+ (NSPoint) getDefaultOrigin {
	CGFloat x = [[NSUserDefaults standardUserDefaults] floatForKey: DEFAULT_ORIGIN_X_KEY];
	CGFloat y = [[NSUserDefaults standardUserDefaults] floatForKey: DEFAULT_ORIGIN_Y_KEY];
	if (x == 0 || y == 0) {
		NSRect screen = [[NSScreen mainScreen] visibleFrame];
		NSLog(@"Main screen info, x: %f, y: %f, width: %f, height: %f", screen.origin.x, screen.origin.y, screen.size.width, screen.size.height);
		x = screen.size.width / 2;
		y = screen.size.height / 2;
	} else {
		NSLog(@"Found and using previous coordinates.");
	}

	return NSMakePoint(x, y);
}

@end


@interface AppDelegate: NSObject<NSApplicationDelegate> {
@private
	ClockWindow *clockWindow;
}
@end

@implementation AppDelegate 
- (void) applicationDidFinishLaunching: (NSNotification*)aNotification {
	clockWindow = [ClockWindow new];
	[clockWindow makeKeyAndOrderFront: self];

}
@end


int main(int argc, char **argv) {
	NSApplication *app = [NSApplication sharedApplication];
	[app setDelegate: [AppDelegate new]];
	[app run];
	return 0;
}
