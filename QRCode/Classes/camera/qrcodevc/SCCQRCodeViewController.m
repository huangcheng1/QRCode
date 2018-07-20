//
//  SCCQRCodeViewController.m
//  Pods
//
//  Created by huang cheng on 2017/2/15.
//
//

#import "SCCQRCodeViewController.h"
#import <CoreImage/CoreImage.h>

@interface SCCQRCodeViewController () <SCCQRCodeCameraManagerDelegate,SCCQRCodeCameraViewDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate>

@property (nonatomic,strong) UIView *bottomView;

@end

@implementation SCCQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor grayColor];
    self.title = @"扫一扫";
    
    [self cameraViewStartRecording];
    
    if (self.navigationController && self.navigationController.viewControllers.count <= 1) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissNav)];
    }
    if (self.navigationController.navigationBar) {
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"相册" style:UIBarButtonSystemItemDone target:self action:@selector(selectFormAblum)];
    }
}

- (void)selectFormAblum{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

//选中图片的回调
-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *content = @"" ;
    //取出选中的图片
    UIImage *pickImage = info[UIImagePickerControllerOriginalImage];
    CIImage *ciImage = [[CIImage alloc]initWithImage:pickImage];
    
    //创建探测器
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    NSArray *feature = [detector featuresInImage:ciImage];
    
    //取出探测到的数据
    for (CIQRCodeFeature *result in feature) {
        content = result.messageString;
    }
    NSLog(@"content %@",content);
}

- (void)dismissNav{
    if([self.cameraManager respondsToSelector:@selector(stopRunning)]){
        [self.cameraManager stopRunning];//开始相机输入
    }
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear: animated];
    if([self.cameraManager respondsToSelector:@selector(startRunning)]){
        [self.cameraManager startRunning];//开始相机输入
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self.cameraView setFrame:self.view.bounds];
}

- (void)setupSession{
    
    NSError *error;
    [self.cameraManager setupSessionWithPreset:AVCaptureSessionPresetPhoto error:&error];
    if (error) {
        NSLog(@"setup Session error: %@", error);
    }
}

- (void)addSubviews{
    
    [self.view addSubview:self.cameraView];
    [self.view addSubview:self.bottomView];
}

- (void)cameraViewStartRecording{
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无法使用相机" message:@"请在iPhone“设置－隐私－相机“中允许访问相机" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles: @"前往设置", nil];
            alert.delegate = self;
            [alert show];
            [self addSubviews];
            return;
        }
        else if (status == AVAuthorizationStatusNotDetermined){
            
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
                if (granted) {
                    [self setupSession];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _cameraView = [SCCQRCodeCameraView initWithFrame:self.view.bounds captureSession: self.cameraManager.captureSession];
                    [_cameraView setDelegate:self];
                    [self addSubviews];
                    [self.view setNeedsLayout];
                    if([self.cameraManager respondsToSelector:@selector(startRunning)]){
                        [self.cameraManager startRunning];//开始相机输入
                    }
                });
            }];
            return;
        }else if(status == AVAuthorizationStatusAuthorized) {
           
            [self setupSession];
            [self addSubviews];
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 1) {
    
        NSURL* url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if([[UIApplication sharedApplication] canOpenURL:url]) {
                    
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}


- (void) hasFoundQRCodeMessage:(NSString*)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_disableClose) {
            
            if ([self.delegate respondsToSelector:@selector(didCatchQRCodeMessage:viewController:)]) {
                [self.delegate didCatchQRCodeMessage:message viewController:self];
            }
        }else {
            [self dismissNav];
            if ([self.delegate respondsToSelector:@selector(didCatchQRCodeMessage:)]) {
                [self.delegate didCatchQRCodeMessage:message];
            }
        }
    });
}

- (void) hasFoundQRCodeError:(NSString*)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_disableClose) {
          
            if ([self.delegate respondsToSelector:@selector(didCatchQRCodeError:viewController:)]) {
                [self.delegate didCatchQRCodeError:message viewController:self];
            }
        }else {
            [self dismissNav];
            if ([self.delegate respondsToSelector:@selector(didCatchQRCodeError:)]) {
                [self.delegate didCatchQRCodeError:message];
            }
        }
    });
}

/**
 *  缩放
 *
 *  @param cameraView
 *  @param point
 */
- (void)cameraView:(UIView *)cameraView exposureAtPoint:(CGPoint)point{
    if (self.cameraManager.videoInput.device.isExposurePointOfInterestSupported) {
        [self.cameraManager exposureAtPoint:[self.cameraManager convertToPointOfInterestFrom:[[(SCCQRCodeCameraView*)cameraView previewLayer] frame] coordinates:point layer:[(SCCQRCodeCameraView*)cameraView previewLayer]]];
    }
}

/**
 *  聚焦
 *
 *  @return
 */
- (BOOL)cameraViewHasFocus{
    return self.cameraManager.hasFocus;
}
/**
 *  聚焦
 *
 *  @param cameraView
 *  @param point
 */
- (void)cameraView:(UIView *)cameraView focusAtPoint:(CGPoint)point{
    if (self.cameraManager.videoInput.device.isFocusPointOfInterestSupported) {
        [self.cameraManager focustAtPoint:[self.cameraManager convertToPointOfInterestFrom:[[(SCCQRCodeCameraView*)cameraView previewLayer] frame] coordinates:point layer:[(SCCQRCodeCameraView*)cameraView previewLayer]]];
    }
}

- (SCCQRCodeCameraView *) cameraView
{
    if ( !_cameraView ) {
        _cameraView = [SCCQRCodeCameraView initWithFrame:self.view.bounds captureSession: self.cameraManager.captureSession];
        [_cameraView setDelegate:self];
    }
    
    return _cameraView;
}

- (SCCQRCodeCameraManager *)cameraManager{
    if (!_cameraManager) {
        _cameraManager = [[SCCQRCodeCameraManager alloc]init];
        _cameraManager.delegate = self;
    }
    return _cameraManager;
}

- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]initWithFrame:CGRectMake(49, self.view.center.y + 100, self.view.bounds.size.width - 98, 34)];
        UILabel *label = [[UILabel alloc]init];
        label.text = self.bottomTipStr;
        label.frame = _bottomView.bounds;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        [_bottomView addSubview:label];
    }
    return _bottomView;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate{
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

- (NSString *)bottomTipStr{
    
    if (!_bottomTipStr) {
        _bottomTipStr = @"将二维码放入框内，即可自动识别";
    }
    return _bottomTipStr;
}

- (BOOL)disableClose{
    
    if (!_disableClose) {
        
        _disableClose = NO;
    }
    return _disableClose;
}

@end
