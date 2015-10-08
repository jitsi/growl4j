/*
 * growl4j, the OpenSource Java Solution for using Growl.
 * Maintained by the Jitsi community (http://jitsi.org).
 *
 * Copyright @ 2015 Atlassian Pty Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <Cocoa/Cocoa.h>
#include <Growl/Growl.h>
#include "org_growl4j_Growl.h"

@interface Growl :NSObject <GrowlApplicationBridgeDelegate> {
	JavaVM *_vm;
	jobject _obj;
}


+(Growl *) getGrowl;
-(void)setVM:(JavaVM *) vm;
-(JavaVM *) getVM;
-(void) setObj:(jobject)obj;
-(jobject) getObj;
-(id) setSelfAsDelegate;

@end

static Growl *growlInstance = nil;

@implementation Growl

+ (Growl *) getGrowl {
	if (growlInstance == nil) {
        growlInstance = [[Growl alloc] init];
    }
    return growlInstance;
}

- (id) init {
	self = [super init];
    if (self) {
		_vm = NULL;
		_obj = NULL;
	}
    return self;
}

/*
 *	Setter and getter methods for a JavaVM reference representing JVM
 */
- (void)setVM:(JavaVM *)vm {
    _vm = vm;
}

- (JavaVM *)getVM {
	return _vm;
}

/*
 *	Setter and getter methods for a jobject instance reference representing
 *	Java object that called this native code. In this case it is an instance
 *	of Growl class.
 */
-(void)setObj:(jobject)obj {
	if(!_obj) {
		_obj = obj;
	}
}

-(jobject)getObj {
	return _obj;
}

/*
 *	This method sets self as a delegate to Growl. Then Growl daemon can call all
 *	the callbacks.
 */
-(id) setSelfAsDelegate {
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	[GrowlApplicationBridge setGrowlDelegate:self];
	[p release];
}

#pragma mark GAB callbacks

/*
 *	This method is called by Growl and returns a dictionary containing
 *	information about the application. Specifically, an set of all notification
 *	types that application will use, a set of default notification types that
 *	application will use, application name, and it's icon. The returned
 *	dictionary also contains a GROWL_APP_ID which is a bundle identifier of an
 *	app and thus must be unique to an app.
 */
- (NSDictionary *) registrationDictionaryForGrowl {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	JNIEnv *env = NULL;
	
	jint getEnvResult = (*_vm)->GetEnv (_vm, (void **) &env, JNI_VERSION_1_2);
	if (getEnvResult == JNI_EDETACHED) {
		/* current native thread is not attached to JVM. We need to attach it */
		if (0 != (*_vm)->AttachCurrentThread(_vm, (void **)&env, NULL)) {
			/* the thread attachment was unsuccessful */
			[pool release];
			return nil;
		}
	} else if (getEnvResult == JNI_EVERSION) {
		/* JNI_VERSION_1_2 is not supported */
		[pool release];
		return nil;
	}
	
    /* getEnv returned JNI_OK or the thread was succesfully attached to JVM */
	
	NSDictionary *growlDict;				// registration dictionary for Growl
	
	if (_vm && _obj) {
		
		jfieldID fid;						// stores the Java field ID
		jobjectArray jAllNotifications;		// stores an array of Java strings
		jobjectArray jDefaultNotifications;	// stores an array of Java strings
		
		jclass clazz = (*env)->GetObjectClass(env, _obj);
	
        /*		
         *	Read the instance field allNotifications which represent all
         *	notification types 
         */
		fid = (*env)->GetFieldID(
                env,
                clazz,
                "allNotifications",
                "[Ljava/lang/String;");
		if (fid == NULL) {
			/* failed to find the field or other exception occured */
			(*env)->ExceptionClear(env);
			(*env)->DeleteLocalRef(env, clazz);
			(*env)->DeleteLocalRef(env, jAllNotifications);
			(*env)->DeleteLocalRef(env, jDefaultNotifications);
			[pool release];
			return nil;
		}
	
		jAllNotifications = (*env)->GetObjectField(env, _obj, fid);
		jint len = (*env)->GetArrayLength(env, jAllNotifications);
		
		NSMutableArray *allNotifications
            = [NSMutableArray arrayWithCapacity: len];

		/* fill allNotifications with strings from jAllNotifications */
		int i;
		for (i = 0; i < len; i++) {
			
			jstring jstr
                = (*env)->GetObjectArrayElement(env, jAllNotifications, i);
			if (JNI_TRUE == (*env)->ExceptionCheck(env)) {
				/* ArrayIndexOutOfBoundsException occured */
				(*env)->ExceptionClear(env);
				(*env)->DeleteLocalRef(env, jstr);
				(*env)->DeleteLocalRef(env, clazz);
				(*env)->DeleteLocalRef(env, jAllNotifications);
				(*env)->DeleteLocalRef(env, jDefaultNotifications);
				[pool release];
				return nil;
			}
			const jchar *str = (*env)->GetStringChars(env, jstr, NULL);
			NSString *notif;
			if (str == NULL) {
				/* out of memory, clean up */
				(*env)->ExceptionClear(env);
				(*env)->DeleteLocalRef(env, clazz);
				(*env)->DeleteLocalRef(env, jAllNotifications);
				(*env)->DeleteLocalRef(env, jDefaultNotifications);
				(*env)->DeleteLocalRef(env, jstr);
				[pool release];
				return nil;
			} else {
				notif = [NSString stringWithCharacters:(UniChar *)str 
                    length:(*env)->GetStringLength(env, jstr)];
				(*env)->ReleaseStringChars(env, jstr, str);
				(*env)->DeleteLocalRef(env, jstr);
				
				[allNotifications addObject: notif];
			}
		}
		
		(*env)->DeleteLocalRef(env, jAllNotifications);
		
        /* 
         *	Read the instance field defaultNotifications which represents
         *	default notification types 
         */
		
		fid = (*env)->GetFieldID(
                env,
                clazz,
                "defaultNotifications",
                "[Ljava/lang/String;");
		if (fid == NULL) {
			/* failed to find the field */
			(*env)->ExceptionClear(env);
			(*env)->DeleteLocalRef(env, clazz);
			(*env)->DeleteLocalRef(env, jAllNotifications);
			(*env)->DeleteLocalRef(env, jDefaultNotifications);
			[pool release];
			return nil;
		}
		
		jDefaultNotifications = (*env)->GetObjectField(env, _obj, fid);
		len = (*env)->GetArrayLength(env, jDefaultNotifications);
		
		NSMutableArray *defaultNotifications
            = [NSMutableArray arrayWithCapacity: len];
		
		/* fill defaultNotifications with strings from jDefaultNotifications */
		
		for (i = 0; i < len; i++) {
			jstring jstr
                = (*env)->GetObjectArrayElement(env, jDefaultNotifications, i);
			if (JNI_TRUE == (*env)->ExceptionCheck(env)) {
				/* ArrayIndexOutOfBoundsException occured */
				(*env)->ExceptionClear(env);
				(*env)->DeleteLocalRef(env, clazz);
				(*env)->DeleteLocalRef(env, jAllNotifications);
				(*env)->DeleteLocalRef(env, jDefaultNotifications);
				(*env)->DeleteLocalRef(env, jstr);
				[pool release];
				return nil;
			}			
			const jchar *str = (*env)->GetStringChars(env, jstr, NULL);
			NSString *notif;
			if (str == NULL) {
				/* out of memory, clean up */
				(*env)->ExceptionClear(env);
				(*env)->DeleteLocalRef(env, clazz);
				(*env)->DeleteLocalRef(env, jAllNotifications);
				(*env)->DeleteLocalRef(env, jDefaultNotifications);
				(*env)->DeleteLocalRef(env, jstr);
				[pool release];
				return nil;
			} else {
				notif = [NSString stringWithCharacters:(UniChar *)str 
                    length:(*env)->GetStringLength(env, jstr)];
				(*env)->ReleaseStringChars(env, jstr, str);
				(*env)->DeleteLocalRef(env, jstr);
				
				[defaultNotifications addObject: notif];
			}
		}
		
		(*env)->DeleteLocalRef(env, jDefaultNotifications);
		
        /* 
         *	Read the instance field appName
         */
		NSString *appName;
		
		fid = (*env)->GetFieldID(env, clazz, "appName", "Ljava/lang/String;");
		if (fid == NULL) {
			/* failed to find the field */
			(*env)->ExceptionClear(env);
			(*env)->DeleteLocalRef(env, clazz);
			[pool release];
			return nil;
		}
		
		jstring jstr = (*env)->GetObjectField(env, _obj, fid);
		
		const jchar *str = (*env)->GetStringChars(env, jstr, NULL);
		if (str == NULL) {
			/* out of memory, clean up */
			(*env)->ExceptionClear(env);
			(*env)->DeleteLocalRef(env, clazz);
			(*env)->DeleteLocalRef(env, jstr);
			[pool release];
			return nil;
		} else {
			appName = [NSString stringWithCharacters:(UniChar *)str
                length:(*env)->GetStringLength(env, jstr)];
			(*env)->ReleaseStringChars(env, jstr, str);
			(*env)->DeleteLocalRef(env, jstr);
		}
		
        /*
         *	Read the instance field appID
         */
		NSString *appID;
		
		fid = (*env)->GetFieldID(env, clazz, "appID", "Ljava/lang/String;");
		if (fid == NULL) {
			/* failed to find the field */
			(*env)->ExceptionClear(env);
			(*env)->DeleteLocalRef(env, clazz);
			[pool release];
			return nil;
		}
		
		jstring jappId = (*env)->GetObjectField(env, _obj, fid);
		
		const jchar *idstr = (*env)->GetStringChars(env, jappId, NULL);
		if (str == NULL) {
			/* out of memory, clean up */
			(*env)->ExceptionClear(env);
			(*env)->DeleteLocalRef(env, clazz);
			(*env)->DeleteLocalRef(env, jappId);
			[pool release];
			return nil;
		} else {
			appID = [NSString stringWithCharacters:(UniChar *)str
                length:(*env)->GetStringLength(env, jappId)];
			(*env)->ReleaseStringChars(env, jappId, idstr);
			(*env)->DeleteLocalRef(env, jappId);
		}
		
		
        /* 
         *	Read the instance field appIcon 
         */
		fid = (*env)->GetFieldID(env, clazz, "appIcon", "[B");
		if (fid == NULL) {
			/* failed to find the field */
			(*env)->ExceptionClear(env);
			(*env)->DeleteLocalRef(env, clazz);
			[pool release];
			return nil;
		}
		
		jbyteArray jiconArray = (*env)->GetObjectField(env, _obj, fid);
		
		jbyte *icon = (*env)->GetByteArrayElements(env, jiconArray, 0);
		if (icon == NULL) {
			/* out of memory, clean up */
			(*env)->ExceptionClear(env);
			(*env)->DeleteLocalRef(env, clazz);
			(*env)->DeleteLocalRef(env, jiconArray);
			[pool release];
			return nil;
		}
		
		len = (*env)->GetArrayLength(env, jiconArray);

		NSBitmapImageRep *appIconRep = [NSBitmapImageRep imageRepWithData:
            [NSData dataWithBytes: icon length: len]];

		NSData *appIcon = [appIconRep representationUsingType:NSTIFFFileType
            properties:[NSDictionary dictionary]];
		
		(*env)->ReleaseByteArrayElements(env, jiconArray, icon, 0);
		(*env)->DeleteLocalRef(env, clazz);
		
		growlDict = [NSDictionary dictionaryWithObjectsAndKeys:
					 appID, GROWL_APP_ID,
					 appName, GROWL_APP_NAME,
					 allNotifications, GROWL_NOTIFICATIONS_ALL,
					 defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
					 @"1", GROWL_TICKET_VERSION,
					 appIcon, GROWL_APP_ICON_DATA,
					 nil];
	}
	
	/* detach current thread if it was attached */
	if (getEnvResult == JNI_EDETACHED) {
		if (0 != (*_vm)->DetachCurrentThread(_vm)) {
			/* the thread detachment was unsuccessful */
			[pool release];
			return nil;
		}
	}
	[growlDict retain];
	[pool release];
	return growlDict;
}

/*
 *	This is a callback method that Growl calls when user clicks on the
 *	notification. The clickContext is a timestamp used to identify the
 *	notification. 
 */
- (void) growlNotificationWasClicked:(id)clickContext {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    if (clickContext) {
		JNIEnv *env = NULL;
		
		jint getEnvResult = (*_vm)->GetEnv (_vm, (void **) &env, JNI_VERSION_1_2);
		if (getEnvResult == JNI_EDETACHED) {
            // current native thread is not attached to JVM. We need to attach
            // it
			if (0 != (*_vm)->AttachCurrentThread(_vm, (void **)&env, NULL)) {
				/* the thread attachment was unsuccessful */
				[pool release];
				return;
			}
		} else if (getEnvResult == JNI_EVERSION) {
			/* JNI_VERSION_1_2 is not supported */
			[pool release];
			return;			
		}

        // getEnv returned JNI_OK or the thread was succesfully attached to JVM
		
		if (_vm && _obj) {
		
			jclass clazz = (*env)->GetObjectClass(env, _obj);
			if (clazz == NULL) {
				/* failed to find the class or other exception occured */
				(*env)->ExceptionClear(env);
				(*env)->DeleteLocalRef(env, clazz);
				[pool release];
				return;
			}

			jmethodID mid = (*env)->GetMethodID(
                    env,
                    clazz,
                    "growlNotificationWasClicked",
                    "(J)V");
			if (mid == NULL) {
				/* failed to find the method or other exception occured */
				(*env)->ExceptionClear(env);
				(*env)->DeleteLocalRef(env, clazz);
				[pool release];
				return;
			}
			
			(*env)->CallVoidMethod(
                    env, _obj, mid, [clickContext longLongValue]);
			
			if (JNI_TRUE == (*env)->ExceptionCheck(env)) {
				/* An exception occured during method execution */
				(*env)->DeleteLocalRef(env, clazz);
				[pool release];
				return;
			}
			
			(*env)->DeleteLocalRef(env, clazz);
		} 
		
		/* Detach current thread if it was attached */
		if (getEnvResult == JNI_EDETACHED) {
			if (0 != (*_vm)->DetachCurrentThread(_vm)) {
				/* The thread detachment was unsuccessful */
				[pool release];
				return;
			}
		}
	}
	[pool release];
}

/*
 *	This is a callback method that Growl calls when the notification times out. 
 *	The clickContext is a timestamp used to identify the notification. 
 */
- (void) growlNotificationTimedOut:(id)clickContext {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    if (clickContext) {
		JNIEnv *env = NULL;
		
		jint getEnvResult = (*_vm)->GetEnv (_vm, (void **) &env, JNI_VERSION_1_2);
		if (getEnvResult == JNI_EDETACHED) {
            // current native thread is not attached to JVM. We need to attach
            // it
			if (0 != (*_vm)->AttachCurrentThread(_vm, (void **)&env, NULL)) {
				/* the thread attachment was unsuccessful */
				[pool release];
				return;
			}
		} else if (getEnvResult == JNI_EVERSION) {
			/* JNI_VERSION_1_2 is not supported */
			[pool release];
			return;			
		}
		
        // getEnv returned JNI_OK or the thread was succesfully attached to JVM
		
		if (_vm && _obj) {
			
			jclass clazz = (*env)->GetObjectClass(env, _obj);
			if (clazz == NULL) {
				/* failed to find the class or other exception occured */
				(*env)->ExceptionClear(env);
				(*env)->DeleteLocalRef(env, clazz);
				[pool release];
				return;
			}
			
			jmethodID mid = (*env)->GetMethodID(
                    env,
                    clazz,
                    "growlNotificationTimedOut",
                    "(J)V");
			if (mid == NULL) {
				/* failed to find the method or other exception occured */
				(*env)->ExceptionClear(env);
				(*env)->DeleteLocalRef(env, clazz);
				[pool release];
				return;
			}
			
			(*env)->CallVoidMethod(
                    env, _obj, mid, [clickContext longLongValue]);
			
			if (JNI_TRUE == (*env)->ExceptionCheck(env)) {
				/* An exception occured during method execution */
				(*env)->DeleteLocalRef(env, clazz);
				[pool release];
				return;
			}
			
			(*env)->DeleteLocalRef(env, clazz);
		} 
		
		/* Detach current thread if it was attached */
		if (getEnvResult == JNI_EDETACHED) {
			if (0 != (*_vm)->DetachCurrentThread(_vm)) {
				/* The thread detachment was unsuccessful */
				[pool release];
				return;
			}
		}
	}
	[pool release];	
}

- (void) dealloc { 
	_obj = NULL;
	_vm = NULL;
    [super dealloc]; 
}

@end

#pragma mark JNI native methods

/* 
 *	A native method used to send notifications to Growl daemon. 
 */
JNIEXPORT void JNICALL Java_org_growl4j_Growl_showGrowlMessage
(JNIEnv * env, jobject obj, jstring title, jstring body, jstring type, jbyteArray iconArray, jlong context) 
{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	NSString *msgTitle;
	NSString *msgBody;
	NSString *msgType;
	NSData	 *msgIcon;

    /* convert jstring objects title, body, and type to corresponding NSString
     * objects */
	const jchar *_msgTitle = (*env)->GetStringChars(env, title, NULL);
	if (_msgTitle == NULL) {
		/* out of memory */
		[p release];
		return;
	} else {
		msgTitle = [NSString stringWithCharacters:(UniChar *)_msgTitle 
            length:(*env)->GetStringLength(env, title)];
		(*env)->ReleaseStringChars(env, title, _msgTitle);
	}
	
	const jchar *_msgBody = (*env)->GetStringChars(env, body, NULL);
	if (_msgBody == NULL) {
		/* out of memory */
		[p release];
		return;
	} else {
		msgBody = [NSString stringWithCharacters:(UniChar *)_msgBody 
            length:(*env)->GetStringLength(env, body)];
		(*env)->ReleaseStringChars(env, title, _msgBody);
	}
	
	const jchar *_msgType = (*env)->GetStringChars(env, type, NULL);
	if (_msgType == NULL) {
		/* out of memory */
		[p release];
		return;
	} else {
		msgType = [NSString stringWithCharacters:(UniChar *)_msgType
            length:(*env)->GetStringLength(env, type)];
		(*env)->ReleaseStringChars(env, title, _msgType);
	}
	
    /* convert iconArray to NSData object representing image to be shown in
     * notification */
	if (iconArray == NULL) {
		/* use application icon */
		msgIcon = nil;
	} else {
		jbyte *img = (*env)->GetByteArrayElements(env, iconArray, NULL);
		if (img == NULL) {
			/* out of memory */
			[p release];
			return;
		} else {
			NSData *iconBytes = [NSData dataWithBytes: img 
                length: (*env)->GetArrayLength(env, iconArray)];
			msgIcon = [[NSBitmapImageRep imageRepWithData:iconBytes]
                representationUsingType:NSTIFFFileType 
                properties:[NSDictionary dictionary]];
			(*env)->ReleaseByteArrayElements(env, iconArray, img, 0);
		}		
	}
	
	/* convert context to NSNumber */
	NSNumber *timestamp = [NSNumber numberWithLongLong:context];
	
	/* send Growl notification */
	[GrowlApplicationBridge notifyWithTitle:msgTitle
								description:msgBody
						   notificationName:msgType
								   iconData:msgIcon
								   priority:0 
								   isSticky:NO
							   clickContext:timestamp];	
	
	[p release];
}

/*
 *	This method is used to register an application with Growl daemon. It
 *	instantiates a Growl object and passes it a reference to JVM which was used
 *	to call this method. It also passes obj which is a reference to Java object
 *	that called this method. These references are later used in Growl method
 *	that needs to call Java code. After setting references to JVM and the obj,
 *	this method calls setSelfAsDelegate on growl which results in Growl daemon
 *	retrieving necessary info to register the application. Growl daemon does so
 *	by calling registrationDictionaryForGrowl on growl instance. 
 *	
 *	This method returns if it fails to get a reference to JVM and to create a
 *	global reference obj.
 */
JNIEXPORT void JNICALL Java_org_growl4j_Growl_registerWithGrowlDaemon
(JNIEnv * env, jobject obj)
{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	Growl *growl = [Growl getGrowl];
	
	if (![growl getVM]) { 
		JavaVM *vm = NULL;
		if ( 0 != (*env)->GetJavaVM(env, (void *)&vm)) {
			[p release];
            // can't get a reference to JVM. An exception was thrown on Java
            // side
			return;
		} else {
			[growl setVM:vm];
			
            // obj needs to be accessed out of this method scope, thus creating
            // a global ref
			obj = (*env)->NewGlobalRef(env, obj);
			if (obj == NULL) {
				/* out of memory */
				[growl setVM:NULL];
				[p release];
				return;
			}
			[growl setObj:obj];
		}
	}
	[growl setSelfAsDelegate];
	[p release];
}

/*
 *	This method will get focus to calling aplication
 */
JNIEXPORT void JNICALL Java_org_growl4j_Growl_getAppToFront
(JNIEnv *env, jobject obj)
{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	[NSApp activateIgnoringOtherApps:YES];
	[p release];
}

/*
 * This method returns true if Growl is running and false otherwise
 */
JNIEXPORT jboolean JNICALL Java_org_growl4j_Growl_isGrowlRunning
(JNIEnv *env, jobject obj)
{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	if ([GrowlApplicationBridge isGrowlRunning])
	{
		[p release];
		return JNI_TRUE;
	} else {
		[p release];
		return JNI_FALSE;
	}
}

/*
 *	This method deletes the global reference used in Growl to allow GC on Java side.
 */
JNIEXPORT void JNICALL Java_org_growl4j_Growl_doFinalCleanUp
(JNIEnv *env, jobject obj)
{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	Growl *growl = [Growl getGrowl];
	[growl autorelease];
	(*env)->DeleteGlobalRef(env, [growl getObj]);
	[p release];
}
