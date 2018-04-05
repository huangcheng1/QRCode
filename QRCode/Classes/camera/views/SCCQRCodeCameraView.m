//
//  SCCQRCodeCameraView.m
//  Pods
//
//  Created by huang cheng on 2017/2/15.
//
//

#import "SCCQRCodeCameraView.h"

@interface SCCQRCodeCameraView ()

@property (nonatomic,strong) UIImageView *maskView;

@end

@implementation SCCQRCodeCameraView


+ (SCCQRCodeCameraView*)initWithFrame:(CGRect)frame captureSession:(AVCaptureSession *)captureSession {
    return [[self alloc] initWithFrame:frame captureSession:captureSession];
}

- (instancetype)initWithFrame:(CGRect)frame captureSession:(AVCaptureSession*)captureSession {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor blackColor]];
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc]init];
        if (captureSession) {
            [_previewLayer setSession:captureSession];
        }else{
        }
        
        [_previewLayer setFrame:self.bounds];
        if ([_previewLayer respondsToSelector:@selector(connection)]) {
            if ([_previewLayer.connection isVideoOrientationSupported]) {
                [_previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            }
        }
        
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [self.layer addSublayer:_previewLayer];
    }
    [self createGesture];
    [self addSubview:self.maskView];
    [self setOverlayView:CGSizeMake([UIScreen mainScreen].bounds.size.width - 50 * 2, [UIScreen mainScreen].bounds.size.width - 50 * 2)];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.previewLayer setFrame:self.bounds];
    if (self.bounds.size.width > self.bounds.size.height) {
        
        [self setOverlayView:CGSizeMake(self.bounds.size.height - 50 * 2, self.bounds.size.height - 50 * 2)];
    } else {
        
        [self setOverlayView:CGSizeMake([UIScreen mainScreen].bounds.size.width - 50 * 2, [UIScreen mainScreen].bounds.size.width - 50 * 2)];
    }
}

- (void)createGesture {
    
    _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToFocus:)];
    [_singleTap setDelaysTouchesEnded:NO];
    [_singleTap setNumberOfTapsRequired:1];
    [_singleTap setNumberOfTouchesRequired:1];
    [self addGestureRecognizer:_singleTap];
    
}

- (void)setOverlayView:(CGSize)size {
    
    // Constants
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    CGFloat width = size.width;
    CGFloat height = size.height;
    CGFloat margin = (bounds.size.height-size.height)/2 - 64;
    CGFloat marginW = (bounds.size.width-size.width)/2;
    
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0);
    
    //    // Create the bezier path & drawing
    UIBezierPath *clipPath = [UIBezierPath bezierPath];
    [clipPath moveToPoint:CGPointMake(0, 0)];
    [clipPath addLineToPoint:CGPointMake(bounds.size.width, 0)];
    [clipPath addLineToPoint:CGPointMake(bounds.size.width, margin)];
    [clipPath addLineToPoint:CGPointMake(0, margin)];
    [clipPath addLineToPoint:CGPointMake(0, 0)];
    [clipPath closePath];
    
    [clipPath moveToPoint:CGPointMake(0, size.height + margin)];
    [clipPath addLineToPoint:CGPointMake(bounds.size.width, margin + size.height)];
    [clipPath addLineToPoint:CGPointMake(bounds.size.width, CGRectGetHeight(bounds))];
    [clipPath addLineToPoint:CGPointMake(0, CGRectGetHeight(bounds))];
    [clipPath addLineToPoint:CGPointMake(0, margin + size.height)];
    [clipPath closePath];
    
    [clipPath moveToPoint:CGPointMake(0, margin)];
    [clipPath addLineToPoint:CGPointMake(marginW, margin)];
    [clipPath addLineToPoint:CGPointMake(marginW, margin + size.height)];
    [clipPath addLineToPoint:CGPointMake(0, margin + size.height)];
    [clipPath addLineToPoint:CGPointMake(0, margin)];
    [clipPath closePath];
    
    [clipPath moveToPoint:CGPointMake(marginW + size.width , margin)];
    [clipPath addLineToPoint:CGPointMake(CGRectGetWidth(bounds), margin)];
    [clipPath addLineToPoint:CGPointMake(CGRectGetWidth(bounds), margin + size.height)];
    [clipPath addLineToPoint:CGPointMake(marginW + size.width, margin + size.height)];
    [clipPath addLineToPoint:CGPointMake(marginW + size.width, margin)];
    [clipPath closePath];
    
    [[UIColor colorWithWhite:0 alpha:0.4] setFill];
    [clipPath fill];
    
    // Add the square crop
    CGRect rect = CGRectMake(marginW, margin, width, height);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:rect];
    [[UIColor colorWithWhite:1.0 alpha:0.5] setStroke];
    maskPath.lineWidth = 1.0;
    [maskPath stroke];
    
    // Add corner path
    UIBezierPath *joinPath = [UIBezierPath bezierPath];
    joinPath.lineCapStyle = kCGLineJoinMiter;
    
    //top left
    [joinPath moveToPoint:CGPointMake(marginW + 2.5, margin + 0.5)];
    [joinPath addLineToPoint:CGPointMake(marginW + 2.5, margin + 16)];
    
    [joinPath moveToPoint:CGPointMake(marginW + 2.5, margin + 2.5)];
    [joinPath addLineToPoint:CGPointMake(marginW + 16, margin + 2.5)];
    
    //top right
    [joinPath moveToPoint:CGPointMake(marginW + width - 16, margin + 2.5)];
    [joinPath addLineToPoint:CGPointMake(marginW + width - 2.5, margin + 2.5)];
    
    [joinPath moveToPoint:CGPointMake(marginW + width - 2.5, margin + 0.5)];
    [joinPath addLineToPoint:CGPointMake(marginW + width - 2.5, margin + 16)];
    
    //bottom left
    [joinPath moveToPoint:CGPointMake(marginW + 2.5, margin + height - 16)];
    [joinPath addLineToPoint:CGPointMake(marginW + 2.5, margin + height - 0.5)];
    
    [joinPath moveToPoint:CGPointMake(marginW + 2.5, margin + height - 2.5)];
    [joinPath addLineToPoint:CGPointMake(marginW + 16, margin + height - 2.5)];
    
    //bottom right
    [joinPath moveToPoint:CGPointMake(marginW + width - 16, margin + height - 2.5)];
    [joinPath addLineToPoint:CGPointMake(marginW + width - 2.5, margin + height - 2.5)];
    
    [joinPath moveToPoint:CGPointMake(marginW + width - 2.5, margin + height - 16)];
    [joinPath addLineToPoint:CGPointMake(marginW + width - 2.5, margin + height - 0.5)];
    
    [joinPath closePath];
    [[UIColor colorWithRed:1 green:0.75 blue:0 alpha:1] setStroke];
    joinPath.lineWidth = 4.0;
    [joinPath stroke];
    
    //Create the image using the current context.
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.maskView.image = image;
}


- (void) tapToFocus:(UIGestureRecognizer *)recognizer {
    CGPoint tempPoint = (CGPoint)[recognizer locationInView:self];
    if ( [_delegate respondsToSelector:@selector(cameraView:focusAtPoint:)] && CGRectContainsPoint(_previewLayer.frame, tempPoint) ){
        [_delegate cameraView:self focusAtPoint:(CGPoint){ tempPoint.x, tempPoint.y - CGRectGetMinY(_previewLayer.frame) }];
    }
}
- (UIImageView *)maskView{
    if (!_maskView) {
        _maskView = [[UIImageView alloc]initWithFrame:self.bounds];
        _maskView.userInteractionEnabled = NO;
    }
    return _maskView;
}
@end
