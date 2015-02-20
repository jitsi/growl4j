/*
 * growl4j, the OpenSource Java Solution for using Growl.
 * Maintained by the Jitsi community (http://jitsi.org).
 *
 * Distributable under LGPL license. See terms of license at gnu.org.
 */
package org.growl4j;

public interface GrowlCallbacksListener
{
    void growlNotificationWasClicked(Object context);
    void growlNotificationTimedOut(Object context);
}
