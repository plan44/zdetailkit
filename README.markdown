
ZDetailKit was born out of the need to generate editors for complex object in my tasks and calendaring apps
Continuous, EverTaskZ, Tasks+Cal+Sync, SyncML PRO, and SyncML LITE. These apps were based for a long time
on a precedessor framework which generalized detail editing to some extent, but became too complicated to
handle and being not flexible enough for new tasks at hand.
ZDetaiKit is a complete from the ground rewrite of this idea, in a much better structured and modular
approach.

The primary goal of ZDetailKit is to make setting up a detail editor (think app settings, or calendar event entry)
_really_ simple. See the ZDetailKitMinimalDemo sample app to see what this means.

License
-------

ZDetailKit is licensed under the MIT License (see LICENSE.txt).

The only requirement of this license is that you must inlcude the copyright
and the license text when you distribute apps using ZDetailKit.

If that's a problem, I'm open to provide a commercial license for a modest fee,
please contact me at luz@plan44.ch.


Features
--------

- ZUtils as separate, independent utilities
- ZCustomI8n
- TextExpander support
- Valueconnectors as generic component
- Validation
- ZDateTimeCell with all the extended options (suggestion, start/end, masterdate etc.)
- choice manager as mostly generic component
- switch cell can address bits in integer flagwords
- custom input views (like datepicker)
- keychain wrapper


Documentation
-------------

ZDetailKit is documented in the source code such that appledoc (see http://gentlebytes.com/appledoc/)
can generate Apple-style class documentation right in XCode's document viewer.

To create and install the ZDetailKit doc set in XCode:

- install appledoc, for example from homebrew:

    brew appledoc
    
- open ZDetailKit.xcodeproj
- choose the "ZDetailKit appledoc" scheme
- Build it
- You'll get many warnings as I haven't bothered to document every obvious method parameter (yet),
  just ignore these.
- Open the Documentation tab in the XCode Organizer, click the eye icon and you'll see
  a new doc set named "ZDetailKit documentation"
  







