// Flow - media downloader with a glass UI (iOS 14+)
// Own code and design. Personal use; download only content you own or have permission to download.
#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <WebKit/WebKit.h>
#import <PhotosUI/PhotosUI.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <Network/Network.h>
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/time.h>

#pragma mark - Localization (English / Arabic)

static NSString *NotifLang = @"FlowLangChanged";
static BOOL IsAr(void) { return [[NSUserDefaults standardUserDefaults] boolForKey:@"arabic"]; }

static NSDictionary *ArExact(void) {
    static NSDictionary *d;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        d = @{
            @"Add": @"إضافة", @"Downloads": @"التنزيلات", @"Files": @"الملفات", @"Settings": @"الإعدادات",
            @"Paste a link": @"الصق الرابط هنا", @"Paste": @"لصق", @"Download": @"تحميل", @"Clipboard is empty.": @"الحافظة فاضية.",
            @"Direct links": @"الروابط المباشرة", @"Paste a direct link to a file (video, audio, image, PDF, zip...) and Flow downloads it with several fast connections at once. Files go to My Files and show in the Files app.": @"الصق رابط مباشر لأي ملف (فيديو، صوت، صورة، PDF، zip...) وفلو بيحمله بعدة اتصالات سريعة مع بعض. الملفات بتتحفظ في ملفاتي وبتظهر في تطبيق الملفات.",
            @"Coming next": @"جاي في التحديث الجاي", @"YouTube, Facebook, TikTok, X and Instagram links are not supported in this first version. They arrive in the next update, with extractors that update from inside the app.": @"روابط يوتيوب وفيسبوك وتيك توك وX وإنستجرام مش مدعومة في النسخة الأولى دي. هتيجي في التحديث الجاي، بأدوات استخراج بتتحدث من جوا التطبيق.",
            @"Not supported yet": @"مش مدعوم لسه", @"This site needs the extractor update. Direct file links work now.": @"الموقع ده محتاج تحديث أداة الاستخراج. الروابط المباشرة شغالة دلوقتي.",
            @"That does not look like a link.": @"ده مش شكل رابط.", @"Added to Downloads": @"اتضاف للتنزيلات",
            @"Starting…": @"جاري البدء…", @"Downloading": @"جاري التحميل", @"Done": @"اكتمل", @"Failed": @"فشل", @"Canceled": @"اتلغى",
            @"No downloads yet": @"مفيش تنزيلات لسه", @"Paste a link in the Add tab to start.": @"الصق رابط في تبويب إضافة عشان تبدأ.",
            @"Cancel": @"إلغاء", @"Retry": @"إعادة المحاولة", @"Delete": @"حذف", @"Share": @"مشاركة", @"Rename": @"تغيير الاسم", @"Move": @"نقل",
            @"Open": @"فتح", @"OK": @"حسنًا", @"Save": @"حفظ", @"Copied": @"تم النسخ", @"Cleared": @"تم المسح",
            @"My Files": @"ملفاتي", @"All": @"الكل", @"Folders": @"مجلدات", @"Images": @"صور", @"Video": @"فيديو", @"Audio": @"صوت", @"Documents": @"مستندات",
            @"Search": @"بحث", @"New folder": @"مجلد جديد", @"Import files": @"استيراد ملفات", @"Folder name": @"اسم المجلد", @"Name": @"الاسم",
            @"This folder is empty": @"المجلد فاضي", @"Use + to add a folder or import files.": @"استخدم + لإضافة مجلد أو استيراد ملفات.",
            @"Move to": @"نقل إلى", @"Home": @"الرئيسية", @"Delete this item?": @"تحذف العنصر ده؟", @"This cannot be undone.": @"مينفعش التراجع عن ده.",
            @"Could not complete that.": @"معرفتش أكمل العملية.", @"A file with that name already exists.": @"فيه ملف بنفس الاسم.",
            @"Appearance": @"المظهر", @"Automatic": @"تلقائي", @"Light": @"فاتح", @"Black": @"أسود", @"Color theme": @"لون التطبيق", @"Language": @"اللغة",
            @"Developer": @"المطور", @"Clear download history": @"مسح سجل التنزيلات",
            @"Speed": @"السرعة", @"item": @"عنصر", @"items": @"عناصر",
            @"Aurora": @"أورورا", @"Browser": @"المتصفح", @"Select": @"تحديد", @"Done ": @"تم", @"From Photos": @"من الصور", @"New": @"جديد",
            @"About": @"عن التطبيق", @"Legal": @"الاستخدام والقانون", @"Storage": @"المساحة", @"Version": @"الإصدار",
            @"Paste a link, get your file.": @"الصق الرابط واحصل على ملفك.", @"Fast": @"سريع", @"Organized": @"منظم", @"Free": @"مجاني",
            @"Search or enter a web address": @"ابحث أو اكتب عنوان موقع", @"Download this link": @"حمّل الرابط ده", @"Close": @"إغلاق",
            @"Delete selected": @"حذف المحدد", @"Search the web": @"ابحث في الويب", @"Appearance & theme": @"المظهر والألوان", @"Back": @"رجوع",
            @"Personal use only. Download only content you own or have permission to download. You are responsible for following the terms of the sites you use.": @"للاستخدام الشخصي فقط. حمّل بس المحتوى اللي تملكه أو مسموح لك تحمله. إنت المسؤول عن الالتزام بشروط المواقع اللي بتستخدمها.",
            @"Files are saved on your iPhone": @"الملفات بتتحفظ على موبايلك",
            @"Open links in the browser; direct file links start downloading automatically.": @"افتح الروابط في المتصفح، وروابط الملفات المباشرة بتبدأ تتحمل لوحدها.",
            @"Direct file links start downloading.": @"روابط الملفات المباشرة بتبدأ تتحمل.",
            @"Selected": @"محدد", @"Used": @"مستخدم",
            @"M4A (taken from the video)": @"M4A (مأخوذ من الفيديو)", @"AAC audio": @"صوت AAC", @"MP4 (H.264 + AAC)": @"MP4 (فيديو + صوت)", @"MP4 (video + audio)": @"MP4 (فيديو + صوت)",
            @"MP4 (no sound)": @"MP4 (من غير صوت)", @"Original sound (M4A/MP3)": @"الصوت الأصلي (M4A/MP3)", @"Original": @"الأصلي", @"Sound": @"صوت", @"Standard": @"عادي",
            @"MP4 · may include the TikTok watermark": @"MP4 · ممكن فيه علامة تيك توك المائية", @"MP4 · no watermark (if the site offers it)": @"MP4 · من غير علامة مائية (لو الموقع بيوفرها)",
            @"Instagram gives one video quality for public posts.": @"إنستجرام بيدي جودة فيديو واحدة للمنشورات العامة.",
            @"Could not create the file": @"معرفتش أعمل الملف", @"Crimson": @"قرمزي", @"Cyber": @"سايبر", @"Graphite": @"جرافيت", @"Ocean": @"محيط", @"Sunset": @"غروب", @"Violet": @"بنفسجي",
            @"Size unknown": @"الحجم مجهول"
        };
    });
    return d;
}
static NSString *T(NSString *s) {
    if (!IsAr() || !s.length) return s;
    NSString *hit = ArExact()[s];
    if (hit) return hit;
    if ([s hasPrefix:@"YouTube is blocking this connection"]) { NSRange r = [s rangeOfString:@" ["]; return [@"يوتيوب بيمنع الاتصال ده: سيرفر الفيديو مش بيرد من شبكتك. جرّب داتا الموبايل أو VPN." stringByAppendingString:r.location != NSNotFound ? [s substringFromIndex:r.location] : @""]; }
    if ([s hasPrefix:@"Facebook: no public video"]) return @"فيسبوك: مفيش فيديو عام في الرابط ده. الفيديوهات الخاصة أو اللي محتاجة تسجيل دخول مش مدعومة.";
    if ([s hasPrefix:@"Instagram: no public video"]) return @"إنستجرام: مفيش فيديو عام في الرابط ده. الحسابات الخاصة أو اللي محتاجة تسجيل دخول مش مدعومة.";
    if ([s hasPrefix:@"Photo "]) return [@"صورة " stringByAppendingString:[s substringFromIndex:6]];
    if ([s hasPrefix:@"Higher qualities up to "]) { NSScanner *sc = [NSScanner scannerWithString:[s substringFromIndex:23]]; int n = 0; [sc scanInt:&n]; return [NSString stringWithFormat:@"فيه جودات أعلى لحد %dp بس بتستخدم VP9/AV1 واللي الآيفون مش بيشغله. فلو بيعرض لحد 1080p.", n]; }
    if ([s hasPrefix:@"Flow 0."]) return @"Flow 0.1\nبرنامج تحميل بواجهة زجاجية. بيحمل الملفات من الروابط المباشرة بعدة اتصالات سريعة، وبيدير ملفاتك. للاستخدام الشخصي: حمّل بس المحتوى اللي تملكه أو مسموح لك تحمله.";
    return s;
}

static void SwizzleSetter(Class c, SEL orig, SEL repl) { method_exchangeImplementations(class_getInstanceMethod(c, orig), class_getInstanceMethod(c, repl)); }

@interface UILabel (NSLoc) @end
@implementation UILabel (NSLoc) - (void)ns_setText:(NSString *)t { [self ns_setText:T(t)]; } @end
@interface UITextView (NSLoc) @end
@implementation UITextView (NSLoc) - (void)ns_setText:(NSString *)t { [self ns_setText:T(t)]; } @end
@interface UIButton (NSLoc) @end
@implementation UIButton (NSLoc) - (void)ns_setTitle:(NSString *)t forState:(UIControlState)s { [self ns_setTitle:T(t) forState:s]; } @end
@interface UIViewController (NSLoc) @end
@implementation UIViewController (NSLoc) - (void)ns_setTitle:(NSString *)t { [self ns_setTitle:T(t)]; } @end

static void SetupLocalization(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        SwizzleSetter(UILabel.class, @selector(setText:), @selector(ns_setText:));
        SwizzleSetter(UITextView.class, @selector(setText:), @selector(ns_setText:));
        SwizzleSetter(UIButton.class, @selector(setTitle:forState:), @selector(ns_setTitle:forState:));
        SwizzleSetter(UIViewController.class, @selector(setTitle:), @selector(ns_setTitle:));
    });
}
static void ApplyDirection(void) {
    UISemanticContentAttribute a = IsAr() ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeForceLeftToRight;
    [UIView appearance].semanticContentAttribute = a;
    [UINavigationBar appearance].semanticContentAttribute = a;
    [UITabBar appearance].semanticContentAttribute = a;
    [UITableView appearance].semanticContentAttribute = a;
    [UISegmentedControl appearance].semanticContentAttribute = a;
    [UISearchBar appearance].semanticContentAttribute = a;
    [UITextField appearance].semanticContentAttribute = a;
}

static NSString *PrefAccent = @"accent";
static NSString *PrefAppearance = @"appearance";
static NSString *NotifTheme = @"FlowThemeChanged";
static NSString *NotifJobs = @"FlowJobsChanged";
