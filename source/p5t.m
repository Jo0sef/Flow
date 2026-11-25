#pragma mark - Trash (recycle bin)

static NSString *TrashDir(void) {
    NSString *p = [Docs() stringByAppendingPathComponent:@".FlowTrash"];
    [NSFileManager.defaultManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];
    return p;
}
static NSString *TrashIndexPath(void) { return [TrashDir() stringByAppendingPathComponent:@".index.plist"]; }
static NSMutableDictionary *TrashIndex(void) { return [NSMutableDictionary dictionaryWithContentsOfFile:TrashIndexPath()] ?: [NSMutableDictionary dictionary]; }
static void TrashSaveIndex(NSDictionary *d) { [d writeToFile:TrashIndexPath() atomically:YES]; }
// Items whose folder is missing or whose index entry is missing are dropped from the index only (never deletes user data).
static NSArray<NSDictionary *> *TrashItems(void) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSMutableDictionary *idx = TrashIndex(); NSMutableArray *out = [NSMutableArray array]; BOOL changed = NO;
    for (NSString *k in idx.allKeys) {
        NSDictionary *e = idx[k]; NSString *name = e[@"name"]; if (![name isKindOfClass:NSString.class]) { [idx removeObjectForKey:k]; changed = YES; continue; }
        NSString *p = [[TrashDir() stringByAppendingPathComponent:k] stringByAppendingPathComponent:name];
        if (![fm fileExistsAtPath:p]) { [idx removeObjectForKey:k]; [fm removeItemAtPath:[TrashDir() stringByAppendingPathComponent:k] error:nil]; changed = YES; continue; }
        [out addObject:@{ @"id": k, @"name": name, @"path": p, @"orig": e[@"orig"] ?: @"", @"date": e[@"date"] ?: [NSDate date] }];
    }
    if (changed) TrashSaveIndex(idx);
    [out sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [b[@"date"] compare:a[@"date"]]; }];
    return out;
}
static int64_t TrashSize(void) { int64_t n = 0; for (NSDictionary *e in TrashItems()) n += SizeOf(e[@"path"]); return n; }
static BOOL TrashMove(NSString *path) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *k = NSUUID.UUID.UUIDString; NSString *box = [TrashDir() stringByAppendingPathComponent:k];
    [fm createDirectoryAtPath:box withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *dst = [box stringByAppendingPathComponent:path.lastPathComponent];
    if (![fm moveItemAtPath:path toPath:dst error:nil]) { [fm removeItemAtPath:box error:nil]; return NO; }
    NSString *rel = path.stringByDeletingLastPathComponent;
    rel = [rel hasPrefix:Docs()] ? [rel substringFromIndex:Docs().length] : @"";
    NSMutableDictionary *idx = TrashIndex();
    idx[k] = @{ @"name": path.lastPathComponent, @"orig": rel, @"date": [NSDate date] };
    TrashSaveIndex(idx);
    return YES;
}
static NSString *TrashRestore(NSDictionary *e) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *dir = [Docs() stringByAppendingString:e[@"orig"]]; BOOL isd = NO;
    if (![fm fileExistsAtPath:dir isDirectory:&isd] || !isd) dir = Docs();
    NSString *dst = UniquePath(dir, e[@"name"]);
    if (![fm moveItemAtPath:e[@"path"] toPath:dst error:nil]) return nil;
    NSMutableDictionary *idx = TrashIndex(); [idx removeObjectForKey:e[@"id"]]; TrashSaveIndex(idx);
    [fm removeItemAtPath:[TrashDir() stringByAppendingPathComponent:e[@"id"]] error:nil];
    return dst;
}
static void TrashPurge(NSDictionary *e) {
    NSMutableDictionary *idx = TrashIndex(); [idx removeObjectForKey:e[@"id"]]; TrashSaveIndex(idx);
    [NSFileManager.defaultManager removeItemAtPath:[TrashDir() stringByAppendingPathComponent:e[@"id"]] error:nil];
}
static void TrashAutoPurge(void) {
    if (![UD() boolForKey:@"trashauto"]) return;
    NSDate *lim = [NSDate dateWithTimeIntervalSinceNow:-30 * 86400];
    for (NSDictionary *e in TrashItems()) if ([e[@"date"] compare:lim] == NSOrderedAscending) TrashPurge(e);
}

@interface TrashVC : BaseVC <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) UIView *empty;
@property(nonatomic, strong) NSArray<NSDictionary *> *items;
@end
@implementation TrashVC
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = L(@"Trash", @"سلة المحذوفات");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.table = MakeTable(self); [self.view addSubview:self.table];
    AddPull(self.table, self);
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[ [self.table.topAnchor constraintEqualToAnchor:g.topAnchor], [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor], [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] ]];
    self.empty = EmptyState(@"trash", L(@"Trash is empty", @"السلة فاضية"), L(@"Deleted files stay here until you remove them.", @"الملفات اللي بتحذفها بتفضل هنا لحد ما تمسحها."));
    [self.view addSubview:self.empty];
    [NSLayoutConstraint activateConstraints:@[ [self.empty.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor], [self.empty.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-20], [self.empty.widthAnchor constraintLessThanOrEqualToConstant:280] ]];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; TrashAutoPurge(); [self reload]; }
- (void)themeChanged { [super themeChanged]; [self.table reloadData]; }
- (void)reload {
    self.items = TrashItems(); self.empty.hidden = self.items.count > 0;
    UIBarButtonItem *b = [[UIBarButtonItem alloc] initWithTitle:L(@"Empty Trash", @"فضّي السلة") style:UIBarButtonItemStylePlain target:self action:@selector(emptyAll)];
    b.tintColor = [UIColor systemRedColor]; self.navigationItem.rightBarButtonItem = self.items.count ? b : nil;
    [self.table reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifJobs object:nil];
}
- (void)emptyAll {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Empty Trash?", @"تفضّي السلة؟") message:L(@"All items will be deleted forever. This cannot be undone.", @"كل العناصر هتتمسح نهائي. مينفعش التراجع.") preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:L(@"Empty Trash", @"فضّي السلة") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) { for (NSDictionary *e in TrashItems()) TrashPurge(e); [self reload]; }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)restore:(NSDictionary *)e {
    if (!TrashRestore(e)) Alert(self, @"Could not complete that.", nil);
    [self reload];
}
- (void)purge:(NSDictionary *)e {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:L(@"Delete forever?", @"تمسحه نهائي؟") message:L(@"This cannot be undone.", @"مينفعش التراجع عن ده.") preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:L(@"Delete forever", @"مسح نهائي") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) { TrashPurge(e); [self reload]; }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return self.items.count; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    RowCell *c = [t dequeueReusableCellWithIdentifier:@"tr"] ?: [[RowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tr"];
    NSDictionary *e = self.items[ip.row]; int k = KindOf(e[@"path"]);
    c.title.text = e[@"name"]; c.represent = e[@"path"];
    [c setSymbol:KindSymbol(k) color:KindColor(k) ring:-1];
    c.pill.hidden = YES; c.check.hidden = YES;
    NSDateFormatter *f = [NSDateFormatter new]; f.dateStyle = NSDateFormatterMediumStyle; f.timeStyle = NSDateFormatterNoStyle;
    if (IsAr()) f.locale = [NSLocale localeWithLocaleIdentifier:@"ar_EG"];
    c.sub.text = [NSString stringWithFormat:@"%@  ·  %@ %@", FmtSize(SizeOf(e[@"path"])), L(@"Deleted", @"اتحذف"), [f stringFromDate:e[@"date"]]];
    c.more.hidden = NO;
    UIAction *r = [UIAction actionWithTitle:L(@"Restore", @"استرجاع") image:[UIImage systemImageNamed:@"arrow.uturn.backward"] identifier:nil handler:^(UIAction *x) { [self restore:e]; }];
    UIAction *d = [UIAction actionWithTitle:L(@"Delete forever", @"مسح نهائي") image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(UIAction *x) { [self purge:e]; }];
    d.attributes = UIMenuElementAttributesDestructive;
    c.more.menu = [UIMenu menuWithTitle:@"" children:@[ r, d ]]; c.more.showsMenuAsPrimaryAction = YES;
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [t deselectRowAtIndexPath:ip animated:YES];
    NSDictionary *e = self.items[ip.row];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:e[@"name"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [a addAction:[UIAlertAction actionWithTitle:L(@"Restore", @"استرجاع") style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { [self restore:e]; }]];
    [a addAction:[UIAlertAction actionWithTitle:L(@"Delete forever", @"مسح نهائي") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) { [self purge:e]; }]];
    [a addAction:[UIAlertAction actionWithTitle:T(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    a.popoverPresentationController.sourceView = self.view; a.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height - 40, 1, 1);
    [self presentViewController:a animated:YES completion:nil];
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)t trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    NSDictionary *e = self.items[ip.row];
    UIContextualAction *d = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:L(@"Delete forever", @"مسح نهائي") handler:^(UIContextualAction *a, UIView *v, void (^h)(BOOL)) { [self purge:e]; h(YES); }];
    return [UISwipeActionsConfiguration configurationWithActions:@[ d ]];
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)t leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    NSDictionary *e = self.items[ip.row];
    UIContextualAction *r = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:L(@"Restore", @"استرجاع") handler:^(UIContextualAction *a, UIView *v, void (^h)(BOOL)) { [self restore:e]; h(YES); }];
    r.backgroundColor = [UIColor systemGreenColor];
    return [UISwipeActionsConfiguration configurationWithActions:@[ r ]];
}
- (void)pullRefresh { TrashAutoPurge(); [self reload]; EndPull(self.table); }
@end
