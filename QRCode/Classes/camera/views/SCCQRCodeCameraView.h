//
//  SCCQRCodeCameraView.h
//  Pods
//
//  Created by huang cheng on 2017/2/15.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol SCCQRCodeCameraViewDelegate <NSObject>

@optional


/*
 focus
 */
- (void)cameraView:(UIView *)cameraView focusAtPoint:(CGPoint)point;


/*
 exposure
 */
- (void)cameraView:(UIView *)cameraView exposureAtPoint:(CGPoint)point;

- (BOOL)cameraViewHasFocus;

- (CGFloat)cameraMaxScale;

@end

@interface SCCQRCodeCameraView : UIView

//预览 camera preview layer
@property (nonatomic, strong , readonly) AVCaptureVideoPreviewLayer *previewLayer;

//单击 single tap for focus
@property (nonatomic, strong , readonly) UITapGestureRecognizer *singleTap;

@property (nonatomic,weak) id <SCCQRCodeCameraViewDelegate> delegate;

+ (SCCQRCodeCameraView *) initWithFrame:(CGRect)frame captureSession:(AVCaptureSession *)captureSession;

@end
