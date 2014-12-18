import UIKit
import ImageIO

public class AnimatedView: UIView {
  private var frames: [AnimatedFrame] = []
  private var currentFrameIndex = 0

  public var isAnimated: Bool {
    return frames.count > 1
  }

  public var isAnimating: Bool {
    return !displayLink.paused
  }

  public func setAnimatedFramesWithData(data: NSData) {
    curry(prepareFrames) <^> CGImageSourceCreateWithData(data, nil) <*> frame.size
    attachDisplayLink()
    pauseAnimation()
  }

  private var displayLink = CADisplayLink()
  private var timeSinceLastUpdate: NSTimeInterval = 0

  func updateLayer() {
    let frame = frames[currentFrameIndex]
    timeSinceLastUpdate += displayLink.duration

    if timeSinceLastUpdate >= frame.duration {
      timeSinceLastUpdate -= frame.duration
      currentFrameIndex = ++currentFrameIndex % frames.count
      layer.contents = frames[currentFrameIndex].image?.CGImage
    }
  }

  private func prepareFrames(imageSource: CGImageSourceRef, size: CGSize) {
    let numberOfFrames = Int(CGImageSourceGetCount(imageSource))
    frames.reserveCapacity(numberOfFrames)

    frames = reduce(0..<numberOfFrames, frames) { accum, index in
      let frameDuration = CGImageSourceGIFFrameDuration(imageSource, index)
      let frameImageRef = CGImageSourceCreateImageAtIndex(imageSource, UInt(index), nil)
      let frame = UIImage(CGImage: frameImageRef)?.resize(size)
      let animatedFrame = AnimatedFrame(image: frame, duration: frameDuration)

      return accum + [animatedFrame]
    }
  }

  private func attachDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: "updateLayer")
    displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
  }

  deinit {
    displayLink.invalidate()
  }

  public func pauseAnimation() {
    displayLink.paused = true
  }

  public func resumeAnimation() {
    if isAnimated {
      displayLink.paused = false
    }
  }
}
