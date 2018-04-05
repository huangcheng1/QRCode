//
//  SCCQRCodeViewController.h
//  Pods
//
//  Created by huang cheng on 2017/2/15.
//
//

#import <UIKit/UIKit.h>
#import "SCCQRCodeCameraManager.h"
#import "SCCQRCodeCameraView.h"

@protocol SCCQRCodeViewControllerDelegate <NSObject>

@optional

- (void)didCatchQRCodeMessage:(NSString*)message;
- (void)didCatchQRCodeError:(NSString*)error;

- (void)didCatchQRCodeMessage:(NSString *)message viewController:(UIViewController *)vc;
- (void)didCatchQRCodeError:(NSString*)error viewController:(UIViewController *)vc;

@end

@interface SCCQRCodeViewController : UIViewController

@property (nonatomic,weak) id<SCCQRCodeViewControllerDelegate>delegate;
@property (nonatomic,strong) SCCQRCodeCameraView *cameraView;
@property (nonatomic,strong) SCCQRCodeCameraManager *cameraManager;

@property (nonatomic,copy) NSString* bottomTipStr;
@property (nonatomic,assign) BOOL disableClose;

@end
