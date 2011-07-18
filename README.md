## PSStackedView - put your UIViewControllers in a stack, inspired by Twitter's iPAD UI.

After reviewing other stacked implementations, i wrote my own solutions from scratch.
This one lets you add plain UIViewControllers to a PSStackedViewRootViewController, working much like a UINavigationController.

All the hard parts, moving, shadows, rounded borders is taken care of.

## Getting Started

Much like UINavigationController, it's a good idea to put your PSStackedViewRootController in the AppDelegate:
`@property (nonatomic, retain) PSStackedViewRootController *stackController;`

Create the stack in application:didFinishLaunchingWithOptions:
`TVTabbedMenuViewController *menuController = [[[TVTabbedMenuViewController alloc] init] autorelease];
self.stackController = [[[PSStackedViewRootController alloc] initWithRootViewController:menuController] autorelease];
[self.stackController pushViewController:channelController fromViewController:nil animated:NO];
window.rootViewController = self.stackController;`

PSStackedViewRootController's rootViewController is in the background and its left part is always visible. Adjust the size with leftInset and largeLeftInset.


## Roadmap
- Add (conditional) support for the new child view controller system in iOS5
- Bouncing
- Better shadow & memory management

## License
Licensed under MIT. Use it for whatever you want, in commercial apps or open source.
I just wand a little contribution somewhere in your about box.

## Alternatives
There are some open source and commerical stacked implementations out there, yet none of them were flexible enough to fit my needs. Special thanks to Cocoacontrols for [this article](http://cocoacontrols.com/posts/how-to-build-the-twitter-ipad-user-experience).

* [StackScrollView](https://github.com/raweng/StackScrollView) (BSD)
* [CLCascade](https://github.com/creativelabs/CLCascade) (Apache 2.0)
* [stackcordion.git](https://github.com/openfinancedev/stackcordion.git) (CCPL)