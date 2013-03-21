
ZDetailKit
==========

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=luz&url=https://github.com/plan44/zdetailkit&title=ZDetailKit&language=&tags=github&category=software)

ZDetailKit was born out of the need to generate editors for complex object in my tasks and calendaring apps
Continuous, EverTaskZ, Tasks+Cal+Sync, SyncML PRO/LITE. These apps were based for a long time
on a precedessor framework which generalized detail editing to some extent already, but became too complicated to
handle and was not flexible enough for new tasks at hand.
ZDetaiKit is a complete from the ground rewrite of this idea, with a much better structured and modular
approach.

The primary goal of ZDetailKit is to make setting up a complex detail editors (think app settings,
or calendar event entry) _really_ simple and focused. See the ZDetailKitMinimalDemo sample app to 
see what this means.

The approach taken was to provide a way to build detail editors in a mostly declarative way, but
without giving up the flexibility of actual coding. So setup of the average detail screen
usually consists of a linear piece of code, creating and configuring the editor elements one by one,
linking them to the model data using ZValueConnector (a kind of bindings).
But because it is code and not a static description, it is also  possible to generate
the editor structure from metadata. For example, one could easily parse iOS settings .plists
or core data models and generate UI automatically.

License
-------

ZDetailKit is licensed under the MIT License (see LICENSE.txt).

The only requirement of this license is that you *must include the copyright
and the license text* when you distribute apps using ZDetailKit.

If that's a problem, I am open to provide a commercial license, please contact me at [luz@plan44.ch](mailto:luz@plan44.ch).


Features
--------

- Based on value connectors (ZValueConnector) - a generic way to dynamically bind model data
  to editing controls, can also be used outside of ZDetailKit.
- Makes use of ObjC blocks - a lot of behaviour can be customized by supplying code blocks to
  standard components without subclassing.
- Based on KVC (key value coding) and KVO (key value observing) standard mechanisms
- Full validation of input, before edits are commited, from subdetail editor through
  value parsing and transformation, down to the data model.
- supports NSValueTransformer and NSFormatter
- Immediate (live) representation of model values in the UI, as well as
  load + cancel/save semantics supported.
- An interacting pair of view controllers (ZDetailTableViewController) and table
  cell (ZDetailViewBaseCell) handles table setup, presentation, expanding/collapsing
  groups, opening subdetail editors mostly automatic.
- Various subclasses of ZDetailViewBaseCell provide ready-to use editors for switches,
  sliders, texts, date and time, choice lists, keychain-stored password, color and
  even a MapKit based location picker.
- Support for custom input views (like keyboard, sliding in and out from bottom of the screen),
  for example for UIPickerView.
- Subclassing ZDetailViewBaseCell to create new editors is simple. Base class provides
  many services that _can_ be used, but does not interfere with normal UITableViewCell
  behaviour.
- Support for TextExpander integration in all text editors.
- Along with ZDetailKit come a few generic utility classes, categories and functions,
  collectively called ZUtils, including support for user-aided internationalisation
  (great for beta apps), date math, keychain wrapper etc.
- Minimum target OS: iOS 5.0


Getting Started
---------------

- Clone the github repository

    `git clone https://github.com/plan44/zdetailkit`

- Open the ZDetailKit.xcodeproj

- Build and run the samples:
  
  + ZDetailKitMinimalDemo is good to see how to get started (one single method to look at)
  + ZDetailKitFullDemo is an elaborate sample, showing all detail editors, presentation
    modes, cell styles. While more complex overall, ZDetailKitFullDemo is good for picking
    code snippets showing the setup of individual cells.

- Build the documentation (see separate paragraph below) to make it available in XCode;
  then have a look at class descriptions for an overview.

- Use ZDetailKit in your own app. It is just a bunch of files (still waiting for official Apple support
  for third-party iOS frameworks), so it's nothing more than adding the files to your project.
  My recommended way to do that is:
  + clone ZDetailKit as a submodule into a subfolder of your project
  
     `git submodule add https://github.com/plan44/zdetailkit`

     `git submodule init`

     `git submodule update`
     
    (you can also just copy the files if you're not a git addict or hate submodules)

  + drag and drop the "ZDetailKit" and "ZUtils" folders into your XCode project
  + let XCode create "groups for each added folder" (_not_ folder references!)
  + check the target(s) you want to use ZDetailKit with
  + If you want to use the MapKit based location picker (ZLocationCell/ZMapLocationEdit),
    add CoreLocation and MapKit frameworks to your project.
  + If you want to use the keychain based password cell (ZKeyChainSecretCell, ZKeyChainWrapper),
    add Security framework to you project.


Documentation
-------------

ZDetailKit is documented in the source code such that appledoc (see [gentlebytes.com/appledoc](http://gentlebytes.com/appledoc/), a fantastic tool!)
can generate and install Apple-style class documentation right into XCode's documentation system.

To create and install the ZDetailKit doc set in XCode:

- install appledoc, I recommend from [homebrew](http://mxcl.github.com/homebrew/):

    `brew install appledoc`

- open ZDetailKit.xcodeproj
- choose the "ZDetailKit appledoc" scheme
- Build it
- You'll get many warnings as I haven't bothered to document every obvious method parameter (yet),
  just ignore these.
- Open the Documentation tab in the XCode Organizer, click the eye icon and you'll see
  a new doc set named "ZDetailKit documentation"

Please note: some versions of appledoc generated docsets caused XCode 4.6 to crash when
double-option-clicking keywords or even on startup. If you run into the startup problem,
delete ch.plan44.ZDetailKit.docset from ~/Library/Developer/Shared/Documentation/DocSets,
install a better/newer version of appledoc and regenerate the docs.


Supporting ZDetailKit
---------------------

1. use it!
2. spread the word
3. contribute patches, issue reports and new functionality
4. Buy plan44.ch products - sales revenue is paying the time for contributing to opensource projects :-)

If you want me to do a specific feature in ZDetailKit on contract basis, please contact me at [luz@plan44.ch](mailto:luz@plan44.ch)


(c) 2013 by Lukas Zeller / [plan44.ch](www.plan44.ch)







