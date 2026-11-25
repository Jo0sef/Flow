
#pragma mark - UI helpers

static void Pin(UIView *v, UIView *p, UIEdgeInsets i) {
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [v.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:i.left], [v.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-i.right],
        [v.topAnchor constraintEqualToAnchor:p.topAnchor constant:i.top], [v.bottomAnchor constraintEqualToAnchor:p.bottomAnchor constant:-i.bottom] ]];
}
static UIImage *Sym(NSString *name, CGFloat size, UIFontWeight w) {
    UIImageSymbolConfiguration *c = [UIImageSymbolConfiguration configurationWithPointSize:size weight:w];
    return [UIImage systemImageNamed:name withConfiguration:c] ?: [UIImage systemImageNamed:@"doc" withConfiguration:c];
}
static UITableView *MakeTable(id owner) {
    UITableView *t = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    t.translatesAutoresizingMaskIntoConstraints = NO; t.backgroundColor = UIColor.clearColor; t.separatorStyle = UITableViewCellSeparatorStyleNone;
    t.dataSource = owner; t.delegate = owner; t.contentInset = UIEdgeInsetsMake(0, 0, 110, 0); t.verticalScrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 70, 0);
    t.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic; t.showsVerticalScrollIndicator = NO;
    return t;
}
static UIColor *KindColor(int k) {
    switch (k) { case 0: return Theme.accent; case 1: return [UIColor systemPinkColor]; case 2: return [UIColor systemPurpleColor]; case 3: return [UIColor systemOrangeColor];
        case 4: return [UIColor systemTealColor]; case 5: return [UIColor systemYellowColor]; default: return [UIColor systemGrayColor]; }
}
static void Share(UIViewController *vc, NSString *path) {
    UIActivityViewController *v = [[UIActivityViewController alloc] initWithActivityItems:@[ [NSURL fileURLWithPath:path] ] applicationActivities:nil];
    v.popoverPresentationController.sourceView = vc.view;
    v.popoverPresentationController.sourceRect = CGRectMake(vc.view.bounds.size.width / 2, vc.view.bounds.size.height / 2, 1, 1);
    [vc presentViewController:v animated:YES completion:nil];
}

#pragma mark - Row cell (Downloads and Files)

@interface RowCell : UITableViewCell
@property(nonatomic, strong) GlassView *card;
@property(nonatomic, strong) RingView *ring;
@property(nonatomic, strong) UILabel *title, *sub, *pill;
@property(nonatomic, strong) UIStackView *meta;
@property(nonatomic, strong) UIButton *more;
@property(nonatomic, strong) UIImageView *check, *thumb;
@property(nonatomic, copy) NSString *represent;
@end
@implementation RowCell
- (instancetype)initWithStyle:(UITableViewCellStyle)st reuseIdentifier:(NSString *)rid {
    if ((self = [super initWithStyle:st reuseIdentifier:rid])) {
        self.backgroundColor = UIColor.clearColor; self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.card = [GlassView new]; self.card.translatesAutoresizingMaskIntoConstraints = NO; self.card.radius = 24; [self.contentView addSubview:self.card];
        Pin(self.card, self.contentView, UIEdgeInsetsMake(6, 16, 6, 16));
        self.ring = [RingView new]; self.ring.translatesAutoresizingMaskIntoConstraints = NO;
        self.title = Label(@"", 16, UIFontWeightBold, nil); self.title.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.sub = Label(@"", 13, UIFontWeightMedium, UIColor.secondaryLabelColor);
        self.pill = Label(@"", 11, UIFontWeightBold, UIColor.whiteColor); self.pill.textAlignment = NSTextAlignmentCenter;
        self.pill.layer.cornerRadius = 10; self.pill.clipsToBounds = YES;
        self.meta = [[UIStackView alloc] initWithArrangedSubviews:@[ self.pill, self.sub ]]; self.meta.spacing = 8; self.meta.alignment = UIStackViewAlignmentCenter; self.meta.translatesAutoresizingMaskIntoConstraints = NO;
        self.more = [UIButton buttonWithType:UIButtonTypeCustom]; self.more.translatesAutoresizingMaskIntoConstraints = NO;
        [self.more setImage:Sym(@"ellipsis", 15, UIFontWeightBold) forState:UIControlStateNormal]; self.more.tintColor = UIColor.labelColor;
        self.more.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.22]; self.more.layer.cornerRadius = 18;
        self.more.showsMenuAsPrimaryAction = YES;
        self.thumb = [UIImageView new]; self.thumb.translatesAutoresizingMaskIntoConstraints = NO; self.thumb.contentMode = UIViewContentModeScaleAspectFill; self.thumb.clipsToBounds = YES; self.thumb.layer.cornerRadius = 16; self.thumb.hidden = YES; self.thumb.layer.cornerCurve = kCACornerCurveContinuous;
        self.check = [UIImageView new]; self.check.translatesAutoresizingMaskIntoConstraints = NO; self.check.contentMode = UIViewContentModeCenter; self.check.hidden = YES;
        UIView *c = self.card.content;
        for (UIView *v in @[ self.ring, self.thumb, self.title, self.meta, self.more, self.check ]) [c addSubview:v];
        [NSLayoutConstraint activateConstraints:@[ [self.thumb.leadingAnchor constraintEqualToAnchor:self.ring.leadingAnchor], [self.thumb.trailingAnchor constraintEqualToAnchor:self.ring.trailingAnchor], [self.thumb.topAnchor constraintEqualToAnchor:self.ring.topAnchor], [self.thumb.bottomAnchor constraintEqualToAnchor:self.ring.bottomAnchor] ]];
        [NSLayoutConstraint activateConstraints:@[
            [self.ring.leadingAnchor constraintEqualToAnchor:c.leadingAnchor constant:14], [self.ring.centerYAnchor constraintEqualToAnchor:c.centerYAnchor],
            [self.ring.widthAnchor constraintEqualToConstant:52], [self.ring.heightAnchor constraintEqualToConstant:52],
            [self.more.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-12], [self.more.centerYAnchor constraintEqualToAnchor:c.centerYAnchor],
            [self.more.widthAnchor constraintEqualToConstant:36], [self.more.heightAnchor constraintEqualToConstant:36],
            [self.check.centerXAnchor constraintEqualToAnchor:self.more.centerXAnchor], [self.check.centerYAnchor constraintEqualToAnchor:self.more.centerYAnchor],
            [self.title.leadingAnchor constraintEqualToAnchor:self.ring.trailingAnchor constant:12], [self.title.trailingAnchor constraintEqualToAnchor:self.more.leadingAnchor constant:-10],
            [self.title.topAnchor constraintEqualToAnchor:c.topAnchor constant:16],
            [self.meta.leadingAnchor constraintEqualToAnchor:self.title.leadingAnchor], [self.meta.trailingAnchor constraintLessThanOrEqualToAnchor:self.more.leadingAnchor constant:-8],
            [self.meta.topAnchor constraintEqualToAnchor:self.title.bottomAnchor constant:7],
            [self.pill.heightAnchor constraintEqualToConstant:20], [self.pill.widthAnchor constraintGreaterThanOrEqualToConstant:64],
            [c.bottomAnchor constraintEqualToAnchor:self.meta.bottomAnchor constant:16] ]];
    }
    return self;
}
- (void)setSymbol:(NSString *)n color:(UIColor *)col ring:(CGFloat)p {
    self.ring.icon.image = Sym(n, 22, UIFontWeightSemibold); self.ring.icon.tintColor = col;
    self.ring.tile = [col colorWithAlphaComponent:0.2]; self.ring.progress = p; self.thumb.hidden = YES; self.thumb.image = nil;
}
- (void)prepareForReuse { [super prepareForReuse]; self.thumb.hidden = YES; self.thumb.image = nil; self.represent = nil; }
- (void)setThumbImage:(UIImage *)i { self.thumb.image = i; self.thumb.hidden = i == nil; }
- (void)setPillText:(NSString *)t color:(UIColor *)c { self.pill.hidden = t.length == 0; self.pill.text = T(t); self.pill.backgroundColor = c; }
- (void)setSelecting:(BOOL)sel selected:(BOOL)on {
    self.more.hidden = sel; self.check.hidden = !sel;
    self.check.image = Sym(on ? @"checkmark.circle.fill" : @"circle", 24, UIFontWeightRegular);
    self.check.tintColor = on ? Theme.accent : UIColor.tertiaryLabelColor;
}
@end


static void OpenFile(UIViewController *vc, NSString *path);
