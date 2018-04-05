//
//  SCCQRCodeCameraManager.m
//  Pods
//
//  Created by huang cheng on 2017/2/15.
//
//

#import "SCCQRCodeCameraManager.h"

@interface SCCQRCodeCameraManager (AVCaptureFileOutputRecordingDelegate)<AVCaptureFileOutputRecordingDelegate,AVCaptureMetadataOutputObjectsDelegate>
@end

@interface SCCQRCodeCameraManager () {
    AVCaptureStillImageOutput *_stillImageOutput;
    AVCaptureMetadataOutput *_metadataOutput;
    CGFloat _maxScale;
}

- (AVCaptureDevice*)cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice*)frontCamera;
- (AVCaptureDevice*)backCamera;

@end

@implementation SCCQRCodeCameraManager

#pragma Class methods

+ (AVCaptureConnection *)connectionWithMediaType:(NSString*)mediaType fromConnections:(NSArray*)connections{
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in connections ) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([port.mediaType isEqual:mediaType]) {
                videoConnection = connection;
                break;
            }
        }
        if (connection) {
            break;
        }
    }
    return videoConnection;
}

#pragma mark - life cycle

- (instancetype)init{
    self = [super init];
    if (self) {
        _maxScale = 1.0;
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(captureSessionDidStartRunning:) name:AVCaptureSessionDidStartRunningNotification object:_captureSession];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [_captureSession stopRunning];
    
    _captureSession = nil;
    _stillImageOutput = nil;
    _metadataOutput = nil;
    _videoInput = nil;
}

- (BOOL)setupSessionWithPreset:(NSString *)sessionPreset error:(NSError *__autoreleasing *)error{
    _videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:[self backCamera] error:error];
    _stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
    [_stillImageOutput setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
    
    _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
    
    
    _captureSession = [[AVCaptureSession alloc]init];
    
    if ([_captureSession canAddInput:_videoInput]) {
        [_captureSession addInput:_videoInput];
    }
    if ([_captureSession canAddOutput:_stillImageOutput]) {
        [_captureSession addOutput:_stillImageOutput];
    }
    if ([_captureSession canAddOutput:_metadataOutput]) {
        [_captureSession addOutput:_metadataOutput];
    }
    
    [_captureSession setSessionPreset:sessionPreset];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("kScanQRCodeQueueName", NULL);
    [_metadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    // 设置元数据类型 AVMetadataObjectTypeQRCode
#if !TARGET_OS_SIMULATOR
    [_metadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
#endif
    [self setFlashMode:AVCaptureFlashModeOff];
    return YES;
    
}

- (void)captureSessionDidStartRunning:(NSNotification *)notification{
    if ([_delegate respondsToSelector:@selector(captureSessionDidStartRunning)]) {
        [_delegate captureSessionDidStartRunning];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        NSString *result;
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            result = metadataObj.stringValue;
        } else {
            if ([self.delegate respondsToSelector:@selector(hasFoundQRCodeError:)]) {
                [self.delegate hasFoundQRCodeError:@"未发现二维码"];
            }
        }
        [self stopRunning];
        if ([self.delegate respondsToSelector:@selector(hasFoundQRCodeMessage:)]) {
            [self.delegate hasFoundQRCodeMessage:result];
        }
    }
}

#pragma mark - focus and exposure

- (void)focustAtPoint:(CGPoint)point{
    AVCaptureDevice *device = _videoInput.device;
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        }else{
            if ([_delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
                [_delegate acquiringDeviceLockFailedWithError:error];
            }
        }
    }
    
}

- (void)exposureAtPoint:(CGPoint)point{
    AVCaptureDevice *device = _videoInput.device;
    if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.exposurePointOfInterest = point;
            device.exposureMode = AVCaptureExposureModeAutoExpose;
            [device unlockForConfiguration];
        }else{
            if ([_delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
                [_delegate acquiringDeviceLockFailedWithError:error];
            }
        }
    }
}

- (CGPoint)convertToPointOfInterestFrom:(CGRect)frame coordinates:(CGPoint)viewCoordinates layer:(AVCaptureVideoPreviewLayer *)layer{
    
    CGPoint pointOfInterest = (CGPoint){ 0.5f, 0.5f };
    CGSize frameSize = frame.size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = layer;
    
    if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] )
    pointOfInterest = (CGPoint){ viewCoordinates.y / frameSize.height, 1.0f - (viewCoordinates.x / frameSize.width) };
    else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in self.videoInput.ports) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = 0.5f;
                CGFloat yc = 0.5f;
                
                if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.0f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.0f - (point.x / x2);
                        }
                    }
                } else if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.0f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.0f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = (CGPoint){ xc, yc };
                break;
            }
        }
    }
    
    return pointOfInterest;
}

#pragma mark - camera action

- (void)startRunning{
    [_captureSession startRunning];
}

- (void)stopRunning{
    [_captureSession stopRunning];
}

- (void)setCameraMaxScale:(CGFloat)maxScale{
    _maxScale = maxScale;
}

- (CGFloat)cameraMaxScale{//获取系统最大的缩放
    AVCaptureConnection *videoConnection = [SCCQRCodeCameraManager connectionWithMediaType:AVMediaTypeVideo fromConnections:_stillImageOutput.connections];
    return videoConnection.videoMaxScaleAndCropFactor;
}

- (BOOL)cameraToggle{
    BOOL success = NO;
    if ([self hasMutipleCameras]) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = _videoInput.device.position;
        
        if (position == AVCaptureDevicePositionBack) {
            newVideoInput = [[AVCaptureDeviceInput alloc]initWithDevice:[self frontCamera] error:&error];
        }
        else if (position == AVCaptureDevicePositionFront) {
            newVideoInput = [[AVCaptureDeviceInput alloc]initWithDevice:[self backCamera] error:&error];
        }else
        goto bail;
        
        if (newVideoInput !=nil) {
            [_captureSession beginConfiguration];
            [_captureSession removeInput:_videoInput];
            if ([_captureSession canAddInput:newVideoInput]) {
                [_captureSession addInput:newVideoInput];
                _videoInput = newVideoInput;
            }else{
                [_captureSession addInput:_videoInput];
            }
            
            [_captureSession commitConfiguration];
            success = YES;
        }else if (error){
            if ([_delegate respondsToSelector:@selector(someOtherError:)]) {
                [_delegate someOtherError:error];
            }
        }
    }
bail:
    return success;
}

- (BOOL)hasMutipleCameras{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1 ? YES : NO;
}

- (BOOL)hasFlash{
    return _videoInput.device.hasFlash;
}

- (AVCaptureFlashMode)flashMode{
    return _videoInput.device.flashMode;
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode{
    AVCaptureDevice *device = _videoInput.device;
    if ([device isFlashModeSupported:flashMode] && device.flashMode != flashMode) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        }else{
            if ([_delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
                [_delegate acquiringDeviceLockFailedWithError:error];
            }
        }
    }
}

- (BOOL)hasTorch{
    return _videoInput.device.hasTorch;
}

- (AVCaptureTorchMode)torchMode{
    return _videoInput.device.torchMode;
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode{
    
    AVCaptureDevice *device = _videoInput.device;
    if ([device isTorchModeSupported:torchMode] && device.torchMode != torchMode) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.torchMode = torchMode;
            [device unlockForConfiguration];
        }else{
            if ([_delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
                [_delegate acquiringDeviceLockFailedWithError:error];
            }
        }
    }
}

- (BOOL)hasFocus{
    AVCaptureDevice *device = _videoInput.device;
    return [device isFocusModeSupported:AVCaptureFocusModeLocked] || [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] || [device isFocusModeSupported:AVCaptureFocusModeAutoFocus];
}

- (AVCaptureFocusMode)focusMode{
    return _videoInput.device.focusMode;
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode{
    
    AVCaptureDevice *device = _videoInput.device;
    if ([device isFocusModeSupported:focusMode] && device.focusMode != focusMode) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusMode = focusMode;
            [device unlockForConfiguration];
        }else{
            if ([_delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
                [_delegate acquiringDeviceLockFailedWithError:error];
            }
        }
    }
}

- (BOOL)hasExposure{
    AVCaptureDevice *device = _videoInput.device;
    return [device isExposureModeSupported:AVCaptureExposureModeAutoExpose] || [device isExposureModeSupported:AVCaptureExposureModeLocked] || [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure];
}

- (AVCaptureExposureMode)exposureMode{
    return _videoInput.device.exposureMode;
}

- (void)setExposureMode:(AVCaptureExposureMode)exposureMode{
    
    AVCaptureDevice *device = _videoInput.device;
    if ([device isExposureModeSupported:exposureMode] && device.exposureMode != exposureMode) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.exposureMode = exposureMode;
            [device unlockForConfiguration];
        }else{
            if ([_delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
                [_delegate acquiringDeviceLockFailedWithError:error];
            }
        }
    }
}

- (BOOL)hasWhiteBalance{
    AVCaptureDevice *device = _videoInput.device;
    return  [device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked] ||
    [device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance];
}

- (AVCaptureWhiteBalanceMode)whiteBalanceMode{
    return _videoInput.device.whiteBalanceMode;
}

- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode{
    
    AVCaptureDevice *device = _videoInput.device;
    if ([device isWhiteBalanceModeSupported:whiteBalanceMode] && device.whiteBalanceMode != whiteBalanceMode) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.whiteBalanceMode = whiteBalanceMode;
            [device unlockForConfiguration];
        }else{
            if ([_delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
                [_delegate acquiringDeviceLockFailedWithError:error];
            }
        }
    }
}

- (NSUInteger)cameraCount{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

#pragma mark - private method

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    __block AVCaptureDevice *deviceBlock = nil;
    
    [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AVCaptureDevice *device = (AVCaptureDevice*)obj;
        if ([device position] == position) {
            deviceBlock = device;
            *stop = YES;
        }
    }];
    return deviceBlock;
}

- (AVCaptureDevice *)frontCamera{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backCamera{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

@end
