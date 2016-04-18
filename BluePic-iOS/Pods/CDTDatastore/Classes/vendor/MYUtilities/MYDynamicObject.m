//
//  CouchDynamicObject.m
//  MYUtilities
//
//  Created by Jens Alfke on 8/6/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYDynamicObject.h"
#import "Test.h"
#import <ctype.h>
#import <objc/runtime.h>


#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#define USE_BLOCKS (__IPHONE_OS_VERSION_MIN_REQUIRED >= 50000)
#else
#define USE_BLOCKS (MAC_OS_X_VERSION_MIN_REQUIRED >= 1070)
#endif


@implementation MYDynamicObject


// Abstract implementations for subclasses to override:

- (id) getValueOfProperty: (NSString*)property {
    NSAssert(NO, @"No such property %@.%@", [self class], property);
    return nil;
}

- (BOOL) setValue: (id)value ofProperty: (NSString*)property {
    return NO;
}


#pragma mark - SELECTOR-TO-PROPERTY NAME MAPPING:


NS_INLINE BOOL isGetter(const char* name) {
    if (!name[0] || name[0]=='_' || name[strlen(name)-1] == ':')
        return NO;                    // If it has parameters it's not a getter
    if (strncmp(name, "get", 3) == 0)
        return NO;                    // Ignore "getXXX" variants of getter syntax
    return YES;
}

NS_INLINE BOOL isSetter(const char* name) {
    return strncmp("set", name, 3) == 0 && name[strlen(name)-1] == ':';
}

// IDEA: to speed this code up, create a map from SEL to NSString mapping selectors to their keys.

// converts a getter selector to an NSString, equivalent to NSStringFromSelector().
NS_INLINE NSString *getterKey(SEL sel) {
    return [NSString stringWithUTF8String:sel_getName(sel)];
}

// converts a setter selector, of the form "set<Key>:" to an NSString of the form @"<key>".
NS_INLINE NSString *setterKey(SEL sel) {
    const char* name = sel_getName(sel) + 3; // skip past 'set'
    size_t length = strlen(name);
    char buffer[1 + length];
    strcpy(buffer, name);
    buffer[0] = (char)tolower(buffer[0]);  // lowercase the property name
    buffer[length - 1] = '\0';       // and remove the ':'
    return [NSString stringWithUTF8String:buffer];
}

+ (NSString*) getterKey: (SEL)sel   {return getterKey(sel);}
+ (NSString*) setterKey: (SEL)sel   {return setterKey(sel);}



#pragma mark - GENERIC ACCESSOR METHOD IMPS:


#if USE_BLOCKS

static inline void setIdProperty(MYDynamicObject *self, NSString* property, id value) {
    BOOL result = [self setValue: value ofProperty: property];
    NSCAssert(result, @"Property %@.%@ is not settable", [self class], property);
}

#else

static id getIdProperty(MYDynamicObject *self, SEL _cmd) {
    return [self getValueOfProperty: getterKey(_cmd)];
}

static void setIdProperty(MYDynamicObject *self, SEL _cmd, id value) {
    NSString* property = setterKey(_cmd);
    BOOL result = [self setValue: value ofProperty: property];
    NSCAssert(result, @"Property %@.%@ is not settable", [self class], property);
}

static int getIntProperty(MYDynamicObject *self, SEL _cmd) {
    return [getIdProperty(self,_cmd) intValue];
}

static void setIntProperty(MYDynamicObject *self, SEL _cmd, int value) {
    setIdProperty(self, _cmd, [NSNumber numberWithInt:value]);
}

static bool getBoolProperty(MYDynamicObject *self, SEL _cmd) {
    return [getIdProperty(self,_cmd) boolValue];
}

static void setBoolProperty(MYDynamicObject *self, SEL _cmd, bool value) {
    setIdProperty(self, _cmd, [NSNumber numberWithBool:value]);
}

static double getDoubleProperty(MYDynamicObject *self, SEL _cmd) {
    id number = getIdProperty(self,_cmd);
    return number ?[number doubleValue] :0.0;
}

static void setDoubleProperty(MYDynamicObject *self, SEL _cmd, double value) {
    setIdProperty(self, _cmd, [NSNumber numberWithDouble:value]);
}

#endif // USE_BLOCKS


#pragma mark - PROPERTY INTROSPECTION:


+ (NSSet*) propertyNames {
    static NSMutableDictionary* classToNames;
    if (!classToNames)
        classToNames = [[NSMutableDictionary alloc] init];
    
    if (self == [MYDynamicObject class])
        return [NSSet set];
    
    NSSet* cachedPropertyNames = [classToNames objectForKey:self];
    if (cachedPropertyNames)
        return cachedPropertyNames;
    
    NSMutableSet* propertyNames = [NSMutableSet set];
    objc_property_t* propertiesExcludingSuperclass = class_copyPropertyList(self, NULL);
    if (propertiesExcludingSuperclass) {
        objc_property_t* propertyPtr = propertiesExcludingSuperclass;
        while (*propertyPtr)
            [propertyNames addObject:[NSString stringWithUTF8String:property_getName(*propertyPtr++)]];
        free(propertiesExcludingSuperclass);
    }
    [propertyNames unionSet:[[self superclass] propertyNames]];
    [classToNames setObject: propertyNames forKey: (id)self];
    return propertyNames;
}


// Look up the encoded type of a property, and whether it's settable or readonly
static const char* getPropertyType(objc_property_t property, BOOL *outIsSettable) {
    *outIsSettable = YES;
    const char *result = "@";
    
    // Copy property attributes into a writeable buffer:
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    
    // Scan the comma-delimited sections of the string:
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        switch (attribute[0]) {
            case 'T':       // Property type in @encode format
                result = (const char *)[[NSData dataWithBytes: (attribute + 1) 
                                                       length: strlen(attribute)] bytes];
                break;
            case 'R':       // Read-only indicator
                *outIsSettable = NO;
                break;
        }
    }
    return result;
}


// Look up a class's property by name, and find its type and which class declared it
static BOOL getPropertyInfo(Class cls, 
                            NSString *propertyName, 
                            BOOL setter,
                            Class *declaredInClass,
                            const char* *propertyType) {
    // Find the property declaration:
    const char *name = [propertyName UTF8String];
    objc_property_t property = class_getProperty(cls, name);
    if (!property) {
        if (![propertyName hasPrefix: @"primitive"]) {   // Ignore "primitiveXXX" KVC accessors
            Log(@"%@ has no dynamic property named '%@' -- failure likely", cls, propertyName);
        }
        *propertyType = NULL;
        return NO;
    }

    // Find the class that introduced this property, as cls may have just inherited it:
    do {
        *declaredInClass = cls;
        cls = class_getSuperclass(cls);
    } while (class_getProperty(cls, name) == property);
    
    // Get the property's type:
    BOOL isSettable;
    *propertyType = getPropertyType(property, &isSettable);
    if (setter && !isSettable) {
        // Asked for a setter, but property is readonly:
        *propertyType = NULL;
        return NO;
    }
    return YES;
}


static Class classFromType(const char* propertyType) {
    size_t len = strlen(propertyType);
    if (propertyType[0] != _C_ID || propertyType[1] != '"' || propertyType[len-1] != '"')
        return NULL;
    char className[len - 2];
    strlcpy(className, propertyType + 2, len - 2);
    return objc_getClass(className);
}


+ (Class) classOfProperty: (NSString*)propertyName {
    Class declaredInClass;
    const char* propertyType;
    if (!getPropertyInfo(self, propertyName, NO, &declaredInClass, &propertyType))
        return Nil;
    return classFromType(propertyType);
}


+ (IMP) impForGetterOfProperty: (NSString*)property ofClass: (Class)propertyClass {
#if USE_BLOCKS
    return imp_implementationWithBlock(^id(MYDynamicObject* receiver) {
        return [receiver getValueOfProperty: property];
    });
#else
    return (IMP)getIdProperty;
#endif
}

+ (IMP) impForSetterOfProperty: (NSString*)property ofClass: (Class)propertyClass {
#if USE_BLOCKS
    return imp_implementationWithBlock(^(MYDynamicObject* receiver, id value) {
        setIdProperty(receiver, property, value);
    });
#else
    return (IMP)setIdProperty;
#endif
}


+ (IMP) impForGetterOfProperty: (NSString*)property ofType: (const char*)propertyType {
    switch (propertyType[0]) {
        case _C_ID:
            return [self impForGetterOfProperty: property ofClass: classFromType(propertyType)];
        case _C_INT:
        case _C_SHT:
        case _C_USHT:
        case _C_CHR:
        case _C_UCHR:
#if USE_BLOCKS
            return imp_implementationWithBlock(^int(MYDynamicObject* receiver) {
                return [[receiver getValueOfProperty: property] intValue];
            });
#else
            return (IMP)getIntProperty;
#endif
        case _C_BOOL:
#if USE_BLOCKS
            return imp_implementationWithBlock(^bool(MYDynamicObject* receiver) {
                return [[receiver getValueOfProperty: property] boolValue];
            });
#else
            return (IMP)getBoolProperty;
#endif
        case _C_DBL:
#if USE_BLOCKS
            return imp_implementationWithBlock(^double(MYDynamicObject* receiver) {
                return [[receiver getValueOfProperty: property] doubleValue];
            });
#else
            return (IMP)getDoubleProperty;
#endif
        default:
            // TODO: handle more scalar property types.
            return NULL;
    }
}

+ (IMP) impForSetterOfProperty: (NSString*)property ofType: (const char*)propertyType {
    switch (propertyType[0]) {
        case _C_ID:
            return [self impForSetterOfProperty: property ofClass: classFromType(propertyType)];
        case _C_INT:
        case _C_SHT:
        case _C_USHT:
        case _C_CHR:            // Note that "BOOL" is a typedef so it compiles to 'char'
        case _C_UCHR:
#if USE_BLOCKS
            return imp_implementationWithBlock(^(MYDynamicObject* receiver, int value) {
                setIdProperty(receiver, property, [NSNumber numberWithInt: value]);
            });
#else
            return (IMP)setIntProperty;
#endif
        case _C_BOOL:           // This is the true native C99/C++ "bool" type
#if USE_BLOCKS
            return imp_implementationWithBlock(^(MYDynamicObject* receiver, bool value) {
                setIdProperty(receiver, property, [NSNumber numberWithBool: value]);
            });
#else
            return (IMP)setBoolProperty;
#endif
        case _C_DBL:
#if USE_BLOCKS
            return imp_implementationWithBlock(^(MYDynamicObject* receiver, double value) {
                setIdProperty(receiver, property, [NSNumber numberWithDouble: value]);
            });
#else
            return (IMP)setDoubleProperty;
#endif
        default:
            // TODO: handle more scalar property types.
            return NULL;
    }
}

// The Objective-C runtime calls this method when it's asked about a method that isn't natively
// implemented by this class. The implementation should either call class_addMethod and return YES,
// or return NO.
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    const char *name = sel_getName(sel);
    NSString* key;
    Class declaredInClass;
    const char *propertyType;
    char signature[5];
    IMP accessor = NULL;
    
    if (isSetter(name)) {
        // choose an appropriately typed generic setter function.
        key = setterKey(sel);
        if (getPropertyInfo(self, key, YES, &declaredInClass, &propertyType)) {
            strcpy(signature, "v@: ");
            signature[3] = propertyType[0];
            accessor = [self impForSetterOfProperty: key ofType: propertyType];
        }
    } else if (isGetter(name)) {
        // choose an appropriately typed getter function.
        key = getterKey(sel);
        if (getPropertyInfo(self, key, NO, &declaredInClass, &propertyType)) {
            strcpy(signature, " @:");
            signature[0] = propertyType[0];
            accessor = [self impForGetterOfProperty: key ofType: propertyType];
        }
    } else {
        // Not a getter or setter name.
        return NO;
    }
    
    if (accessor) {
        Log(@"Creating dynamic accessor method -[%@ %s]", declaredInClass, name);
        class_addMethod(declaredInClass, sel, accessor, signature);
        return YES;
    }
    
    if (propertyType) {
        Warn(@"Dynamic property %@.%@ has type '%s' unsupported by %@", 
             self, key, propertyType, self);
    }
    return NO;
}


@end
