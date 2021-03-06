#import "FeatureExtractionAppDelegate.h"

@implementation FeatureExtractionAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UIImage *inputImage = [UIImage imageNamed:@"71yih.png"];    
    GPUImagePicture *blackAndWhiteBoxImage = [[GPUImagePicture alloc] initWithImage:inputImage];
    
    [self testHarrisCornerDetectorAgainstPicture:blackAndWhiteBoxImage withName:@"WhiteBoxes"];
    [self testNobleCornerDetectorAgainstPicture:blackAndWhiteBoxImage withName:@"WhiteBoxes"];
    [self testShiTomasiCornerDetectorAgainstPicture:blackAndWhiteBoxImage withName:@"WhiteBoxes"];
    
    return YES;
}

- (void)testCornerDetector:(GPUImageHarrisCornerDetectionFilter *)cornerDetector ofName:(NSString *)detectorName againstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
{
    [pictureInput removeAllTargets];
    
    [pictureInput addTarget:cornerDetector];
    
    GPUImageCrosshairGenerator *crosshairGenerator = [[GPUImageCrosshairGenerator alloc] init];
    crosshairGenerator.crosshairWidth = 5.0;
    [crosshairGenerator forceProcessingAtSize:[pictureInput outputImageSize]];
    
    [cornerDetector setCornersDetectedBlock:^(GLfloat* cornerArray, NSUInteger cornersDetected, CMTime frameTime) {
        [crosshairGenerator renderCrosshairsFromArray:cornerArray count:cornersDetected frameTime:frameTime];
    }];
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    [pictureInput addTarget:blendFilter];
    pictureInput.targetToIgnoreForUpdates = blendFilter;
    
    [crosshairGenerator addTarget:blendFilter];
    
    [blendFilter prepareForImageCapture];
    [pictureInput processImage];
    
    NSUInteger currentImageIndex = 0;
    for (UIImage *currentImage in cornerDetector.intermediateImages)
    {
        [self saveImage:currentImage fileName:[NSString stringWithFormat:@"%@-%@-%d.png", detectorName, pictureName, currentImageIndex]];
        
        currentImageIndex++;
    }
    
    UIImage *crosshairResult = [blendFilter imageFromCurrentlyProcessedOutput];
    
    [self saveImage:crosshairResult fileName:[NSString stringWithFormat:@"%@-%@-Crosshairs.png", detectorName, pictureName]];
}

- (void)testHarrisCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
{
    GPUImageHarrisCornerDetectionFilter *harrisCornerFilter = [[GPUImageHarrisCornerDetectionFilter alloc] init];
    [self testCornerDetector:harrisCornerFilter ofName:@"Harris" againstPicture:pictureInput withName:pictureName];
}

- (void)testNobleCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
{
    GPUImageNobleCornerDetectionFilter *nobleCornerFilter = [[GPUImageNobleCornerDetectionFilter alloc] init];
    [self testCornerDetector:nobleCornerFilter ofName:@"Noble" againstPicture:pictureInput withName:pictureName];
}

- (void)testShiTomasiCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
{
    GPUImageShiTomasiFeatureDetectionFilter *nobleCornerFilter = [[GPUImageShiTomasiFeatureDetectionFilter alloc] init];
    [self testCornerDetector:nobleCornerFilter ofName:@"ShiTomasi" againstPicture:pictureInput withName:pictureName];
}

- (void)saveImage:(UIImage *)imageToSave fileName:(NSString *)imageName;
{
    NSData *dataForPNGFile = UIImagePNGRepresentation(imageToSave);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSError *error = nil;
    if (![dataForPNGFile writeToFile:[documentsDirectory stringByAppendingPathComponent:imageName] options:NSAtomicWrite error:&error])
    {
        return;
    }
}

@end
