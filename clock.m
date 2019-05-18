#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include "math.h"

const CGFloat WINDOW_SIZE = 175.0;
const CGFloat HAND_WIDTH = 10.0;
const CGFloat HAND_HOUR_HEIGHT = 50.0;
const CGFloat HAND_MINUTE_HEIGHT = 70.0;
const CGFloat DEGREES_IN_RAD = 180.0;
const CGFloat DEGREES_IN_CIRCLE = 360.0;
const CGFloat DEGREES_OFFSET = 90;
const CGFloat DEGREES_PER_HOUR = 30;
const CGFloat DEGREES_PER_MINUTE = 6;

const int HOURS_IN_CLOCK = 12;
const int MINUTES_IN_HOUR = 60;
const int SECONDS_IN_MINUTE = 60;

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

@interface ClockWindow: NSWindow {
@private
	NSImageView *_background;
	ClockHandView *_hourHand;
	ClockHandView *_minuteHand;
	NSTimer *_timer;
}

- (void) updateTime;
- (void) setTimeToHours: (int)h minutes: (int)m seconds: (int)s;

@end

@implementation ClockWindow
	
- (id) init {
	self = [super initWithContentRect: NSMakeRect(0, 0, WINDOW_SIZE, WINDOW_SIZE)
					        styleMask: NSTitledWindowMask | 
					   			  	   NSClosableWindowMask | 
								       NSMiniaturizableWindowMask
					          backing: NSBackingStoreRetained 
					            defer: false];
	if (self) {
		[self setTitle: TITLE];
	
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


int main(int argc, char **argv)
{
	NSApplication *app = [NSApplication sharedApplication];
	[app setDelegate: [AppDelegate new]];
	[app run];
	return 0;
}
