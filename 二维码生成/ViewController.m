//
//  ViewController.m
//  二维码生成
//
//  Created by Orangels on 16/10/12.
//  Copyright © 2016年 ls. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UIButton *btn;
@property (strong, nonatomic) IBOutlet UIImageView *iv;

@end

@implementation ViewController

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

- (IBAction)clickBtn:(id)sender {
    [self.view endEditing:YES];
    //实例化滤镜
    CIFilter* filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    NSLog(@"%@",filter.attributes);
    [filter setDefaults];
    NSData* data = [_textField.text dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    //生成二维码
    CIImage* CIimage = [filter outputImage];
//    UIImage* UIimage = [UIImage imageWithCIImage:CIimage];
//    _iv.image = UIimage;
    //高清二维码
    _iv.image = [self createNonInterpolatedUIImageFormCIImage:CIimage withSize:100];
}

//生成高清二维码  间接转换：CIImage –> CGImageRef –> UIImage
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {
    CGRect extent = CGRectIntegral(image.extent);
    //设置比例
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    size_t height = CGRectGetHeight(extent)*scale;
    size_t width = CGRectGetWidth(extent)*scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
//    return [UIImage imageWithCGImage:scaledImage];
    UIImage* newImage = [UIImage imageWithCGImage:scaledImage];
    return [self imageBlackToTransparent:newImage withRed:234.0f andGreen:138.0f andBlue:45.0f];
}

//设置图片透明度
//providerrelease 的回调函数
void ProviderReleaseData (void *info, const void *data, size_t size){
    free((void*)data);
}

- (UIImage*)imageBlackToTransparent:(UIImage*)image withRed:(CGFloat)red andGreen:(CGFloat)green andBlue:(CGFloat)blue{
    const int imageWidth       = image.size.width;
    const int imageHeight      = image.size.height;
    size_t bytesPerRow         = imageWidth*4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint32_t* rgbImageBuffer   = (uint32_t*)malloc(bytesPerRow*imageHeight);

    CGContextRef context       = CGBitmapContextCreate(rgbImageBuffer,
                                                       imageWidth,
                                                       imageHeight,
                                                       8,
                                                       bytesPerRow,
                                                       colorSpace,
                                                       kCGImageAlphaNoneSkipLast|kCGBitmapByteOrder32Little);
    
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    //遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuffer;
    for (int i = 0; i < pixelNum; i++, pCurPtr++){
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900)    // 将白色变成透明
        {
            // 改成下面的代码，会将图片转成想要的颜色
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = red; //0~255
            ptr[2] = green;
            ptr[1] = blue;
        }
        else
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
    }
    //输出图片
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL,
                                                                  rgbImageBuffer,
                                                                  bytesPerRow*imageHeight,
                                                                  ProviderReleaseData);
    
    CGImageRef imageRef            = CGImageCreate(imageWidth,
                                                   imageHeight,
                                                   8,
                                                   32,
                                                   bytesPerRow,
                                                   colorSpace,
                                                   kCGImageAlphaNoneSkipLast|kCGBitmapByteOrder32Little,
                                                   dataProvider,
                                                   NULL,
                                                   true,
                                                   kCGRenderingIntentDefault);
    
    CGDataProviderRelease(dataProvider);
    UIImage* resultImage           = [UIImage imageWithCGImage:imageRef];
    //释放
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return resultImage;
}

-(void)logAllFilters {
    NSArray *properties = [CIFilter filterNamesInCategory: kCICategoryGenerator];
    NSLog(@"%@", properties);
//    for (NSString *filterName in properties) {
//        CIFilter *fltr = [CIFilter filterWithName:filterName];
//        NSLog(@"%@", [fltr attributes]);
//    }
}



- (void)viewDidLoad {
    [super viewDidLoad];
    [self logAllFilters];
    _textField.delegate = self;
    
}
#pragma mark textdelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.view endEditing:YES];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
