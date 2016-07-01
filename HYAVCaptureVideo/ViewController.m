//
//  ViewController.m
//  HYAVCaptureVideo
//
//  Created by ZhangZheming on 16/6/23.
//  Copyright © 2016年 HY. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize captureSession;
@synthesize imageView;
@synthesize customLayer;
@synthesize prevLayer;
@synthesize brightnessLabel;
@synthesize device;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initCapture];
}

- (void)initCapture
{
    //AVCaptureDevice代表抽象的硬件设备
    // 找到一个合适的AVCaptureDevice
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (![device hasTorch]) {//判断是否有闪光灯
        UIAlertView *alter = [[UIAlertView alloc]initWithTitle:@"提示" message:@"当前设备没有闪光灯，不能提供手电筒功能" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
        [alter show];
    }
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]  error:nil];
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    //captureOutput.minFrameDuration = CMTimeMake(1, 10);
    
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:queue];

    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput];
    [self.captureSession startRunning];
    
    self.customLayer = [CALayer layer];
    self.customLayer.frame = self.view.bounds;
    self.customLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0f, 0, 0, 1);
    self.customLayer.contentsGravity = kCAGravityResizeAspectFill;
    [self.view.layer addSublayer:self.customLayer];
    
    UIButton *startBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 70) / 2, self.view.frame.size.height - 100, 70, 70)];
    [startBtn setImage:[UIImage imageNamed:@"圆"] forState:UIControlStateNormal];
    [startBtn setImage:[UIImage imageNamed:@"拍照"] forState:UIControlStateSelected];
    startBtn.layer.cornerRadius = startBtn.frame.size.height / 2;
    [startBtn addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startBtn];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.frame = CGRectMake(0, 20, self.view.frame.size.width / 3, self.view.frame.size.height / 3);
    [self.view addSubview:self.imageView];
    
    self.brightnessLabel = [[UILabel alloc] init];
    self.brightnessLabel.frame = CGRectMake(10, self.view.frame.size.height - 50, 100, 40);
    self.brightnessLabel.backgroundColor = [UIColor lightGrayColor];
    self.brightnessLabel.textColor = [UIColor whiteColor];
    self.brightnessLabel.font = [UIFont boldSystemFontOfSize:18.0];
    self.brightnessLabel.text = @"0.0";
    self.brightnessLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.brightnessLabel];
    
    self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession]; 
    self.prevLayer.frame = CGRectMake(self.view.frame.size.width - self.view.frame.size.width / 3, 20, self.view.frame.size.width / 3, self.view.frame.size.height / 3);
    self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; 
    [self.view.layer addSublayer: self.prevLayer]; 
}

#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        [self.customLayer performSelectorOnMainThread:@selector(setContents:) withObject: (__bridge id) newImage waitUntilDone:YES];
        
        UIImage *image = [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
        
        CGImageRelease(newImage);
        
        [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
        
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
        CFRelease(metadataDict);
        NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
        float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
        
//        [device lockForConfiguration:nil];
//        [device setTorchMode:brightnessValue > 1 ? AVCaptureTorchModeOff : AVCaptureTorchModeOn];
//        [device unlockForConfiguration];

        [self.brightnessLabel performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"%.2f",brightnessValue] waitUntilDone:YES];
        
//        [self combineWithLeftImage:image rightImage:image];
    }
}

- (IBAction)takePhoto:(id)sender
{
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }else {
        [self.captureSession startRunning];
    }
    UIButton *btn = (UIButton *)sender;
    btn.selected = !btn.selected;
}

- (void)combineWithLeftImage:(UIImage*)leftImage rightImage:(UIImage*)rightImage
{
    CGFloat width = leftImage.size.width * 2;
    CGFloat height = leftImage.size.height;
    CGSize offScreenSize = CGSizeMake(width, height);
    
    UIGraphicsBeginImageContext(offScreenSize);
    
    CGRect rect = CGRectMake(0, 0, width/2, height);
    [leftImage drawInRect:rect];
    
    rect.origin.x += width / 2;
    [rightImage drawInRect:rect];
    
    UIImage* imagez = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    [self saveImageToPhotos:imagez];
}

- (void)saveImageToPhotos:(UIImage*)savedImage
{
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

// 指定回调方法
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *msg = (error != NULL) ? @"保存图片失败" : @"保存图片成功" ;
    NSLog(@"%@",msg);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
