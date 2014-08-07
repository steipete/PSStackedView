## PSStackedView - put your UIViewControllers in a stack, inspired by Twitter's iPAD UI.


NOTE: This component was made for iOS 4. There surely are better ways to do this right now and I'm only keeping this up for historical reasons. Don't use it anymore.




After reviewing other stacked implementations, i wrote my own solutions from scratch.
This one lets you add plain UIViewControllers to a PSStackedViewRootViewController, working much like a UINavigationController.

All the hard parts, moving, shadows, rounded borders is taken care of.

I made it for the iPad-Version of the popular austrian TV app ["3MobileTV"](http://itunes.apple.com/at/app/3mobiletv/id404154552?mt=8).
(You need an austrian 3-SIM to test it, but you can check out the screenshots to get the idea what's possible with it).

Currently there is a positioning bug with small view controllers, I'll fix that in the foreseeable future. Otherwise, it's pretty much a drop-in-replacement for UINavigationController, using regular UIViewControllers. It supports iOS4 upwards, with some special support for iOS5's new view controller containment coming.

It works on the iPad and the iPhone, but the _concept_ is better suited for the iPad.

![PSStackedView](http://f.cl.ly/items/2O1p18263a2Q27223R3h/Screen%20Shot%202011-11-01%20at%206.03.02%20PM.png)

... and custom-skinned, you can build pretty hot interfaces:

[![PSStackedView](http://f.cl.ly/items/2Z0w0D1P0y1h2N1V3d1t/mzl.svmxiutd.png)](http://itunes.apple.com/at/app/3mobiletv/id404154552?mt=8)

## Getting Started

Much like UINavigationController, it's a good idea to put your PSStackedViewRootController in the AppDelegate:

```objc
@property (nonatomic, retain) PSStackedViewRootController *stackController;
```

Create the stack in application:didFinishLaunchingWithOptions:

```objc
ExampleMenuRootController *menuController = [[[ExampleMenuRootController alloc] init] autorelease];
self.stackController = [[[PSStackedViewRootController alloc] initWithRootViewController:menuController] autorelease];
[self.stackController pushViewController:demoViewController fromViewController:nil animated:NO];
window.rootViewController = self.stackController;
```

PSStackedViewRootController's rootViewController is in the background and its left part is always visible. Adjust the size with leftInset and largeLeftInset.

## Roadmap
- Add (conditional) support for the new child view controller system in iOS5
- Appledoc
- lots more

## License
Licensed under MIT. Use it for whatever you want, in commercial apps or open source.
I just wand a little contribution somewhere in your about box.

## Alternatives
There are some open source and commerical stacked implementations out there, yet none of them were flexible enough to fit my needs.
Special thanks to Cocoacontrols for [this article](http://cocoacontrols.com/posts/how-to-build-the-twitter-ipad-user-experience).

* [StackScrollView](https://github.com/raweng/StackScrollView) (BSD)
* [CLCascade](https://github.com/creativelabs/CLCascade) (Apache 2.0)
* [stackcordion.git](https://github.com/openfinancedev/stackcordion.git) (CCPL)
