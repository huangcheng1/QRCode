#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "bitstream.h"
#import "mask.h"
#import "QRCodeGenerator.h"
#import "qrencode.h"
#import "qrinput.h"
#import "qrspec.h"
#import "rscode.h"
#import "split.h"
#import "SCCQRCodeCameraManager.h"
#import "SCCQRCodeViewController.h"
#import "SCCQRCodeCameraView.h"

FOUNDATION_EXPORT double QRCodeVersionNumber;
FOUNDATION_EXPORT const unsigned char QRCodeVersionString[];

