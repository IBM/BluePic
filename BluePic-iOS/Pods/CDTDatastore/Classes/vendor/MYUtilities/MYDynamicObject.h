//
//  MYDynamicObject.h
//  MYUtilities
//
//  Created by Jens Alfke on 8/6/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>


/** A generic class with runtime support for dynamic properties.
    You can subclass this and declare properties in the subclass without needing to implement them or make instance variables; simply note them as '@@dynamic' in the @@implementation.
    The dynamic accessors will be bridged to calls to -getValueOfProperty: and setValue:ofProperty:, allowing you to easily store property values in an NSDictionary or other container. */
@interface MYDynamicObject : NSObject

/** Returns the names of all properties defined in this class and superclasses up to MYDynamicObject. */
+ (NSSet*) propertyNames;

/** Returns the value of a named property.
    This method will only be called for properties that have been declared in the class's @@interface using @@property.
    You must override this method -- the base implementation just raises an exception. */
- (id) getValueOfProperty: (NSString*)property;

/** Sets the value of a named property.
    This method will only be called for properties that have been declared in the class's @@interface using @@property, and are not declared readonly.
    You must override this method -- the base implementation just raises an exception.
    @return YES if the property was set, NO if it isn't settable; an exception will be raised.
    Default implementation returns NO. */
- (BOOL) setValue: (id)value ofProperty: (NSString*)property;


// FOR SUBCLASSES TO CALL:

/** Given the name of an object-valued property, returns the class of the property's value.
    Returns nil if the property doesn't exist, or if its type isn't an object pointer or is 'id'. */
+ (Class) classOfProperty: (NSString*)propertyName;

+ (NSString*) getterKey: (SEL)sel;
+ (NSString*) setterKey: (SEL)sel;

// ADVANCED STUFF FOR SUBCLASSES TO OVERRIDE:

+ (IMP) impForGetterOfProperty: (NSString*)property ofClass: (Class)propertyClass;
+ (IMP) impForSetterOfProperty: (NSString*)property ofClass: (Class)propertyClass;
+ (IMP) impForGetterOfProperty: (NSString*)property ofType: (const char*)propertyType;
+ (IMP) impForSetterOfProperty: (NSString*)property ofType: (const char*)propertyType;

@end
