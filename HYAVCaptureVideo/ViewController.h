//
//  ViewController.h
//  HYAVCaptureVideo
//
//  Created by ZhangZheming on 16/6/23.
//  Copyright © 2016年 HY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/CGImageProperties.h>

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) CALayer *customLayer;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;
@property (nonatomic, strong) AVCaptureDevice *device;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic,strong) UILabel *brightnessLabel;

- (void)initCapture;

@end

