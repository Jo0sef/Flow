#pragma mark - Tools (convert, ringtone, background removal)

@interface Busy : UIView
@property(nonatomic, strong) UILabel *lab;
@end
@implementation Busy
+ (Busy *)show:(UIViewController *)vc text:(NSString *)t {
    UIView *host = vc.view.window ?: vc.view;
    Busy *b = [[Busy alloc] initWithFrame:host.bounds]; b.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    b.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 24; [b addSubview:g];
    UIActivityIndicatorView *sp = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge]; sp.translatesAutoresizingMaskIntoConstraints = NO; [sp startAnimating]; sp.color = UIColor.whiteColor;
    b.lab = Label(t, 15, UIFontWeightSemibold, UIColor.whiteColor); b.lab.textAlignment = NSTextAlignmentCenter; b.lab.numberOfLines = 0;
    [g.content addSubview:sp]; [g.content addSubview:b.lab];
    [NSLayoutConstraint activateConstraints:@[
        [g.centerXAnchor constraintEqualToAnchor:b.centerXAnchor], [g.centerYAnchor constraintEqualToAnchor:b.centerYAnchor], [g.widthAnchor constraintEqualToConstant:220],
        [sp.topAnchor constraintEqualToAnchor:g.content.topAnchor constant:24], [sp.centerXAnchor constraintEqualToAnchor:g.content.centerXAnchor],
        [b.lab.topAnchor constraintEqualToAnchor:sp.bottomAnchor constant:14], [b.lab.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor constant:16], [b.lab.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-16],
        [g.content.bottomAnchor constraintEqualToAnchor:b.lab.bottomAnchor constant:22] ]];
    [host addSubview:b];
    return b;
}
- (void)hide { [self removeFromSuperview]; }
@end

static NSString *ToolsOutDir(void) {
    NSString *p = [Docs() stringByAppendingPathComponent:@"Converted"];
    [NSFileManager.defaultManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];
    return p;
}
static void ToolDone(UIViewController *vc, NSString *out, NSString *err) {
    if (!out) { Alert(vc, @"Could not complete that.", err ?: @""); return; }
    UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Done", @"تم") message:[NSString stringWithFormat:L(@"Saved in My Files > Converted:\n%@", @"اتحفظ في ملفاتي > Converted:\n%@"), out.lastPathComponent] preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Share") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { Share(vc, out); }]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"OK") style:UIAlertActionStyleCancel handler:nil]];
    [vc presentViewController:a animated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil];
}
static void ExportAsset(AVAsset *asset, NSString *preset, AVFileType type, CMTimeRange range, NSString *out, void (^done)(NSString *out, NSString *err)) {
    AVAssetExportSession *ex = [[AVAssetExportSession alloc] initWithAsset:asset presetName:preset];
    if (!ex) { done(nil, L(@"This file cannot be exported with this option", @"الملف ده ميتحولش بالاختيار ده")); return; }
    [NSFileManager.defaultManager removeItemAtPath:out error:nil];
    ex.outputURL = [NSURL fileURLWithPath:out]; ex.outputFileType = type;
    if (CMTIMERANGE_IS_VALID(range) && !CMTIMERANGE_IS_EMPTY(range)) ex.timeRange = range;
    [ex exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ex.status == AVAssetExportSessionStatusCompleted) done(out, nil);
            else { [NSFileManager.defaultManager removeItemAtPath:out error:nil]; done(nil, ex.error.localizedDescription); }
        });
    }];
}
// kind: 0 mp4 720p, 1 mp4 1080p, 2 m4a audio, 3 compress (medium)
static void ToolConvert(UIViewController *vc, NSString *path, int mode) {
    AVURLAsset *a = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    NSString *base = path.lastPathComponent.stringByDeletingPathExtension;
    NSString *preset, *ext; AVFileType type;
    switch (mode) {
        case 0: preset = AVAssetExportPreset1280x720; ext = @"mp4"; type = AVFileTypeMPEG4; base = [base stringByAppendingString:@" 720p"]; break;
        case 1: preset = AVAssetExportPreset1920x1080; ext = @"mp4"; type = AVFileTypeMPEG4; base = [base stringByAppendingString:@" 1080p"]; break;
        case 2: preset = AVAssetExportPresetAppleM4A; ext = @"m4a"; type = AVFileTypeAppleM4A; break;
        default: preset = AVAssetExportPresetMediumQuality; ext = @"mp4"; type = AVFileTypeMPEG4; base = [base stringByAppendingString:@" small"]; break;
    }
    NSString *out = UniquePath(ToolsOutDir(), [base stringByAppendingPathExtension:ext]);
    Busy *b = [Busy show:vc text:L(@"Converting…", @"بحوّل…")];
    ExportAsset(a, preset, type, kCMTimeRangeInvalid, out, ^(NSString *o, NSString *e) { [b hide]; ToolDone(vc, o, e); });
}
static void ToolRingtone(UIViewController *vc, NSString *path, double start) {
    AVURLAsset *a = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    double dur = CMTimeGetSeconds(a.duration); double len = MIN(30.0, MAX(1.0, dur - start));
    NSString *out = UniquePath(ToolsOutDir(), [[path.lastPathComponent.stringByDeletingPathExtension stringByAppendingString:@" ringtone"] stringByAppendingPathExtension:@"m4r"]);
    NSString *tmp = [TempRoot() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    tmp = [tmp stringByAppendingPathExtension:@"m4a"];
    Busy *b = [Busy show:vc text:L(@"Making ringtone…", @"بعمل نغمة…")];
    ExportAsset(a, AVAssetExportPresetAppleM4A, AVFileTypeAppleM4A, CMTimeRangeMake(CMTimeMakeWithSeconds(start, 600), CMTimeMakeWithSeconds(len, 600)), tmp, ^(NSString *o, NSString *e) {
        [b hide];
        if (!o) { ToolDone(vc, nil, e); return; }
        [NSFileManager.defaultManager moveItemAtPath:o toPath:out error:nil];
        ToolDone(vc, out, nil);
    });
}
static UIImage *Upright(UIImage *img) {
    if (img.imageOrientation == UIImageOrientationUp) return img;
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:img.size];
    return [r imageWithActions:^(UIGraphicsImageRendererContext *c) { [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)]; }];
}
static void ToolRemoveBG(UIViewController *vc, UIImage *src, NSString *name) {
    Busy *b = [Busy show:vc text:L(@"Removing background…", @"بشيل الخلفية…")];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *err = nil; NSString *out = nil;
        @autoreleasepool {
            UIImage *img = Upright(src);
            if (MAX(img.size.width, img.size.height) * img.scale > 3000) {
                CGFloat k = 3000.0 / (MAX(img.size.width, img.size.height) * img.scale);
                UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(img.size.width * k * img.scale, img.size.height * k * img.scale)];
                img = [r imageWithActions:^(UIGraphicsImageRendererContext *c) { [img drawInRect:CGRectMake(0, 0, img.size.width * k * img.scale, img.size.height * k * img.scale)]; }];
            }
            CIImage *ci = [[CIImage alloc] initWithCGImage:img.CGImage];
            VNGeneratePersonSegmentationRequest *req = [VNGeneratePersonSegmentationRequest new];
            req.qualityLevel = VNGeneratePersonSegmentationRequestQualityLevelAccurate; req.outputPixelFormat = kCVPixelFormatType_OneComponent8;
            VNImageRequestHandler *h = [[VNImageRequestHandler alloc] initWithCIImage:ci options:@{}];
            NSError *e = nil;
            if (![h performRequests:@[ req ] error:&e] || !req.results.count) err = e.localizedDescription ?: L(@"No person found in the picture", @"مفيش شخص ظاهر في الصورة");
            else {
                VNPixelBufferObservation *o = req.results.firstObject;
                CIImage *mask = [CIImage imageWithCVPixelBuffer:o.pixelBuffer];
                mask = [mask imageByApplyingTransform:CGAffineTransformMakeScale(ci.extent.size.width / mask.extent.size.width, ci.extent.size.height / mask.extent.size.height)];
                CIFilter *f = [CIFilter filterWithName:@"CIBlendWithMask"];
                [f setValue:ci forKey:kCIInputImageKey]; [f setValue:[CIImage emptyImage] forKey:kCIInputBackgroundImageKey]; [f setValue:mask forKey:kCIInputMaskImageKey];
                CIContext *cx = [CIContext contextWithOptions:nil];
                CGImageRef cg = [cx createCGImage:f.outputImage fromRect:ci.extent];
                if (!cg) err = L(@"Rendering failed", @"الرسم فشل");
                else {
                    NSData *png = UIImagePNGRepresentation([UIImage imageWithCGImage:cg]); CGImageRelease(cg);
                    out = UniquePath(ToolsOutDir(), [[name.stringByDeletingPathExtension stringByAppendingString:@" cutout"] stringByAppendingPathExtension:@"png"]);
                    [png writeToFile:out atomically:YES];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{ [b hide]; ToolDone(vc, out, err); });
    });
}
// Ringtone screen: pick the 30 second window
@interface RingtoneVC : UIViewController
@property(nonatomic, copy) NSString *path;
@property(nonatomic) double dur;
@property(nonatomic, strong) UISlider *slider;
@property(nonatomic, strong) UILabel *info;
@property(nonatomic, strong) AVPlayer *player;
@end
@implementation RingtoneVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    AVURLAsset *a = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:self.path] options:nil]; self.dur = CMTimeGetSeconds(a.duration);
    GlassView *g = [GlassView new]; g.translatesAutoresizingMaskIntoConstraints = NO; g.radius = 28; [self.view addSubview:g];
    UILabel *t = Label(L(@"Ringtone", @"نغمة رنين"), 22, UIFontWeightBold, nil);
    UILabel *n = Label(self.path.lastPathComponent, 14, UIFontWeightMedium, UIColor.secondaryLabelColor); n.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.info = Label(@"", 15, UIFontWeightSemibold, nil);
    self.slider = [UISlider new]; self.slider.translatesAutoresizingMaskIntoConstraints = NO; self.slider.minimumValue = 0; self.slider.maximumValue = MAX(0.0, self.dur - 30.0);
    self.slider.enabled = self.dur > 31; self.slider.tintColor = Theme.accent;
    [self.slider addTarget:self action:@selector(moved) forControlEvents:UIControlEventValueChanged];
    UIButton *pv = GlassButton(L(@"Preview", @"سماع"), self, @selector(preview));
    UIButton *mk = GlassButton(L(@"Create .m4r", @"اعمل .m4r"), self, @selector(make));
    UILabel *h = Label(L(@"The ringtone is the 30 seconds starting at the slider. After creating it, share the .m4r file and add it to your iPhone with 3uTools (Ringtones) or iTunes.", @"النغمة هي 30 ثانية من مكان السلايدر. بعد ما تتعمل، شارك ملف .m4r وضيفه للموبايل من 3uTools (Ringtones) أو iTunes."), 13, UIFontWeightRegular, UIColor.secondaryLabelColor); h.numberOfLines = 0;
    UIButton *x = [UIButton buttonWithType:UIButtonTypeSystem]; x.translatesAutoresizingMaskIntoConstraints = NO; [x setImage:Sym(@"xmark.circle.fill", 26, UIFontWeightRegular) forState:UIControlStateNormal]; x.tintColor = UIColor.secondaryLabelColor; [x addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    for (UIView *v in @[ t, n, self.info, self.slider, pv, mk, h, x ]) [g.content addSubview:v];
    UILayoutGuide *sg = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [g.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16], [g.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16], [g.topAnchor constraintEqualToAnchor:sg.topAnchor constant:24],
        [t.leadingAnchor constraintEqualToAnchor:g.content.leadingAnchor constant:20], [t.topAnchor constraintEqualToAnchor:g.content.topAnchor constant:20],
        [x.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-14], [x.centerYAnchor constraintEqualToAnchor:t.centerYAnchor],
        [n.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [n.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-20], [n.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:6],
        [self.info.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [self.info.topAnchor constraintEqualToAnchor:n.bottomAnchor constant:20],
        [self.slider.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [self.slider.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-20], [self.slider.topAnchor constraintEqualToAnchor:self.info.bottomAnchor constant:10],
        [pv.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [pv.trailingAnchor constraintEqualToAnchor:g.content.trailingAnchor constant:-20], [pv.topAnchor constraintEqualToAnchor:self.slider.bottomAnchor constant:18],
        [mk.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [mk.trailingAnchor constraintEqualToAnchor:pv.trailingAnchor], [mk.topAnchor constraintEqualToAnchor:pv.bottomAnchor constant:10],
        [h.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [h.trailingAnchor constraintEqualToAnchor:pv.trailingAnchor], [h.topAnchor constraintEqualToAnchor:mk.bottomAnchor constant:14],
        [g.content.bottomAnchor constraintEqualToAnchor:h.bottomAnchor constant:20] ]];
    [self moved];
}
- (void)moved {
    double s = self.slider.value, e = MIN(self.dur, s + 30);
    self.info.text = [NSString stringWithFormat:@"%@ %@  →  %@   (%.0f s)", L(@"From", @"من"), FmtDur(s) ?: @"0:00", FmtDur(e), e - s];
    if (s < 1) self.info.text = [NSString stringWithFormat:@"%@ 0:00  →  %@   (%.0f s)", L(@"From", @"من"), FmtDur(e), e - s];
}
- (void)preview {
    [self.player pause];
    self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.path]];
    [self.player seekToTime:CMTimeMakeWithSeconds(self.slider.value, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self.player play];
    __weak RingtoneVC *w = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [w.player pause]; });
}
- (void)make { [self.player pause]; UIViewController *p = self.presentingViewController ?: self; double s = self.slider.value; NSString *path = self.path; [self dismissViewControllerAnimated:YES completion:^{ ToolRingtone(p, path, s); }]; }
- (void)close { [self.player pause]; [self dismissViewControllerAnimated:YES completion:nil]; }
@end

static void OpenRingtone(UIViewController *vc, NSString *path) {
    RingtoneVC *r = [RingtoneVC new]; r.path = path;
    r.modalPresentationStyle = UIModalPresentationOverFullScreen; r.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIView *dim = [[UIView alloc] init]; (void)dim;
    [vc presentViewController:r animated:YES completion:nil];
}

// Choose a file from My Files
@interface FilePickVC : UITableViewController
@property(nonatomic, copy) NSArray<NSString *> *items;
@property(nonatomic, copy) void (^pick)(NSString *path);
@property(nonatomic, copy) NSArray<NSNumber *> *kinds;
@end
@implementation FilePickVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"Choose a file", @"اختار ملف");
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    NSMutableArray *all = [NSMutableArray array];
    for (NSString *f in [NSFileManager.defaultManager enumeratorAtPath:Docs()]) {
        if ([f hasPrefix:@"."] || [f containsString:@"/."]) continue;
        NSString *p = [Docs() stringByAppendingPathComponent:f];
        if ([self.kinds containsObject:@(KindOf(p))]) [all addObject:p];
    }
    self.items = all;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:T(@"Close") style:UIBarButtonItemStylePlain target:self action:@selector(close)];
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return MAX(1, self.items.count); }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    if (!self.items.count) { c.textLabel.text = L(@"No matching files in My Files", @"مفيش ملفات مناسبة في ملفاتي"); c.textLabel.textColor = UIColor.secondaryLabelColor; return c; }
    NSString *p = self.items[ip.row];
    c.textLabel.text = p.lastPathComponent; c.detailTextLabel.text = FmtSize(SizeOf(p)); c.imageView.image = Sym(KindSymbol(KindOf(p)), 20, UIFontWeightRegular); c.imageView.tintColor = KindColor(KindOf(p));
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    if (!self.items.count) return;
    NSString *p = self.items[ip.row]; void (^cb)(NSString *) = self.pick;
    [self dismissViewControllerAnimated:YES completion:^{ if (cb) cb(p); }];
}
@end
static void PickFile(UIViewController *vc, NSArray<NSNumber *> *kinds, void (^pick)(NSString *)) {
    FilePickVC *f = [[FilePickVC alloc] initWithStyle:UITableViewStyleInsetGrouped]; f.kinds = kinds; f.pick = pick;
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:f];
    [vc presentViewController:n animated:YES completion:nil];
}

// Photo picker helper (used by: remove background, change thumbnail, import)
@interface PhotoHelper : NSObject <PHPickerViewControllerDelegate>
@property(nonatomic, copy) void (^onImage)(UIImage *img, NSString *name);
@property(nonatomic, copy) void (^onFiles)(NSArray<NSURL *> *urls);
@end
@implementation PhotoHelper
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    for (PHPickerResult *r in results) {
        NSItemProvider *p = r.itemProvider;
        if (self.onImage && [p canLoadObjectOfClass:UIImage.class]) {
            [p loadObjectOfClass:UIImage.class completionHandler:^(id obj, NSError *e) { if ([obj isKindOfClass:UIImage.class]) dispatch_async(dispatch_get_main_queue(), ^{ self.onImage(obj, p.suggestedName ?: @"photo"); }); }];
        } else if (self.onFiles) {
            NSString *type = p.registeredTypeIdentifiers.firstObject; if (!type) continue;
            [p loadFileRepresentationForTypeIdentifier:type completionHandler:^(NSURL *u, NSError *e) {
                if (!u) return;
                NSString *tmp = [TempRoot() stringByAppendingPathComponent:u.lastPathComponent];
                [NSFileManager.defaultManager removeItemAtPath:tmp error:nil]; [NSFileManager.defaultManager copyItemAtPath:u.path toPath:tmp error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{ self.onFiles(@[ [NSURL fileURLWithPath:tmp] ]); });
            }];
        }
    }
}
@end
static PhotoHelper *gPhoto;
static void PickPhoto(UIViewController *vc, BOOL files, void (^onImage)(UIImage *, NSString *), void (^onFiles)(NSArray<NSURL *> *)) {
    PHPickerConfiguration *c = [[PHPickerConfiguration alloc] init];
    c.selectionLimit = files ? 0 : 1; c.filter = files ? nil : [PHPickerFilter imagesFilter];
    PHPickerViewController *p = [[PHPickerViewController alloc] initWithConfiguration:c];
    gPhoto = [PhotoHelper new]; gPhoto.onImage = onImage; gPhoto.onFiles = onFiles; p.delegate = gPhoto;
    [vc presentViewController:p animated:YES completion:nil];
}

// Tools menu
static void ConvertMenu(UIViewController *vc, NSString *path) {
    int k = KindOf(path);
    UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Convert", @"تحويل") message:path.lastPathComponent preferredStyle:UIAlertControllerStyleActionSheet];
    if (k == 2) {
        [a addAction:[UIAlertAction actionWithTitle:L(@"MP4 video 720p", @"فيديو MP4 بجودة 720p") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { ToolConvert(vc, path, 0); }]];
        [a addAction:[UIAlertAction actionWithTitle:L(@"MP4 video 1080p", @"فيديو MP4 بجودة 1080p") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { ToolConvert(vc, path, 1); }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:L(@"Audio only (M4A)", @"صوت بس (M4A)") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { ToolConvert(vc, path, 2); }]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    a.popoverPresentationController.sourceView = vc.view; a.popoverPresentationController.sourceRect = CGRectMake(vc.view.bounds.size.width / 2, vc.view.bounds.size.height - 40, 1, 1);
    [vc presentViewController:a animated:YES completion:nil];
}
static void RemoveBGPath(UIViewController *vc, NSString *path) {
    UIImage *i = [UIImage imageWithContentsOfFile:path];
    if (!i) { Alert(vc, @"Could not complete that.", nil); return; }
    ToolRemoveBG(vc, i, path.lastPathComponent);
}

@interface ToolsVC : BaseVC <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *table;
@end
@implementation ToolsVC
- (NSArray *)rows {
    return @[ @[ @"arrow.triangle.2.circlepath", L(@"Convert", @"تحويل"), L(@"Video to MP4 or audio (M4A)", @"فيديو لـ MP4 أو صوت (M4A)"), @0 ],
              @[ @"bell.fill", L(@"Ringtone", @"نغمة رنين"), L(@"Cut 30 seconds and make a .m4r file", @"قص 30 ثانية واعمل ملف .m4r"), @1 ],
              @[ @"person.crop.circle.badge.minus", L(@"Remove background (people)", @"إزالة الخلفية (أشخاص)"), L(@"Keeps people only. Objects and animals are not supported.", @"بيسيب الأشخاص بس. الأشياء والحيوانات مش مدعومة."), @2 ] ];
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = L(@"Tools", @"أدوات");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.table = MakeTable(self); [self.view addSubview:self.table];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[ [self.table.topAnchor constraintEqualToAnchor:g.topAnchor], [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor], [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] ]];
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return 3; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    RowCell *c = [t dequeueReusableCellWithIdentifier:@"t"] ?: [[RowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"t"];
    NSArray *r = [self rows][ip.row];
    UIColor *col = @[ [UIColor systemBlueColor], [UIColor systemOrangeColor], [UIColor systemPinkColor] ][ip.row];
    [c setSymbol:r[0] color:col ring:-1]; c.title.text = r[1]; c.sub.text = r[2]; c.sub.numberOfLines = 2; c.pill.hidden = YES; c.more.hidden = YES; c.check.hidden = NO;
    c.check.image = Sym(IsAr() ? @"chevron.backward" : @"chevron.forward", 14, UIFontWeightBold); c.check.tintColor = UIColor.tertiaryLabelColor;
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [t deselectRowAtIndexPath:ip animated:YES];
    NSInteger rw = ip.row;
    if (rw == 0) { PickFile(self, @[ @2, @3 ], ^(NSString *p) { ConvertMenu(self, p); }); }
    else if (rw == 1) { PickFile(self, @[ @2, @3 ], ^(NSString *p) { OpenRingtone(self, p); }); }
    else {
            UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [a addAction:[UIAlertAction actionWithTitle:T(@"From Photos") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { PickPhoto(self, NO, ^(UIImage *i, NSString *n) { ToolRemoveBG(self, i, n); }, nil); }]];
            [a addAction:[UIAlertAction actionWithTitle:L(@"From My Files", @"من ملفاتي") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { PickFile(self, @[ @1 ], ^(NSString *p) { RemoveBGPath(self, p); }); }]];
            [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
            a.popoverPresentationController.sourceView = self.view; a.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height - 40, 1, 1);
            [self presentViewController:a animated:YES completion:nil]; }
}
@end
