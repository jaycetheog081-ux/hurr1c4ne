#import "RadixViewController.h"

#import <UIKit/UIKit.h>

#pragma mark - Radix Appearance

static UIColor *RXBackgroundColor(void) {
    return [UIColor colorWithRed:0.035 green:0.047 blue:0.075 alpha:1.0];
}

static UIColor *RXCardColor(void) {
    return [UIColor colorWithRed:0.075 green:0.090 blue:0.125 alpha:1.0];
}

static UIColor *RXSecondaryColor(void) {
    return [UIColor colorWithRed:0.125 green:0.145 blue:0.190 alpha:1.0];
}

static UIColor *RXAccentColor(void) {
    return [UIColor colorWithRed:0.35 green:0.88 blue:0.63 alpha:1.0];
}

static UIColor *RXPrimaryTextColor(void) {
    return [UIColor colorWithWhite:0.96 alpha:1.0];
}

static UIColor *RXSecondaryTextColor(void) {
    return [UIColor colorWithWhite:0.64 alpha:1.0];
}

static NSString * const RXSourcesDefaultsKey = @"com.hurr1c4ne.radix.sources";
static NSString * const RXDownloadsDefaultsKey = @"com.hurr1c4ne.radix.downloads";

#pragma mark - Radix Tabs

typedef NS_ENUM(NSInteger, RXTab) {
    RXTabHome = 0,
    RXTabPackages,
    RXTabSources,
    RXTabQueue,
    RXTabInstalled
};

#pragma mark - RadixViewController

@interface RadixViewController () <
    UITableViewDataSource,
    UITableViewDelegate,
    UISearchBarDelegate
>

@property (nonatomic, strong) UIView *rootView;
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *bottomBar;

@property (nonatomic, strong) UILabel *brandLabel;
@property (nonatomic, strong) UILabel *pageTitleLabel;
@property (nonatomic, strong) UILabel *pageSubtitleLabel;

@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *sources;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *packages;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *filteredPackages;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *downloadQueue;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *downloadedPackages;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionDownloadTask *> *activeDownloads;

@property (nonatomic, assign) RXTab selectedTab;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isSearching;

@end

@implementation RadixViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = RXBackgroundColor();
    self.navigationController.navigationBarHidden = YES;

    self.sources = [NSMutableArray array];
    self.packages = [NSMutableArray array];
    self.filteredPackages = [NSMutableArray array];
    self.downloadQueue = [NSMutableArray array];
    self.downloadedPackages = [NSMutableArray array];
    self.activeDownloads = [NSMutableDictionary dictionary];

    self.selectedTab = RXTabHome;

    [self loadSavedData];
    [self buildInterface];
    [self showTab:RXTabHome];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.rootView.frame = self.view.bounds;
}

#pragma mark - Saved Data

- (void)loadSavedData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSArray *savedSources = [defaults arrayForKey:RXSourcesDefaultsKey];
    if ([savedSources isKindOfClass:[NSArray class]]) {
        for (id item in savedSources) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [self.sources addObject:item];
            }
        }
    }

    NSArray *savedDownloads = [defaults arrayForKey:RXDownloadsDefaultsKey];
    if ([savedDownloads isKindOfClass:[NSArray class]]) {
        for (id item in savedDownloads) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [self.downloadedPackages addObject:item];
            }
        }
    }
}

- (void)saveSources {
    [[NSUserDefaults standardUserDefaults] setObject:self.sources
                                              forKey:RXSourcesDefaultsKey];
}

- (void)saveDownloadedPackages {
    [[NSUserDefaults standardUserDefaults] setObject:self.downloadedPackages
                                              forKey:RXDownloadsDefaultsKey];
}

#pragma mark - Interface Construction

- (void)buildInterface {
    self.rootView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.rootView.backgroundColor = RXBackgroundColor();
    self.rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                    UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:self.rootView];

    // Create the bottom bar before the content area because the content area's
    // bottom constraint references self.bottomBar.topAnchor.
    [self buildTopBar];
    [self buildBottomBar];
    [self buildContentArea];
}

- (void)buildTopBar {
    self.topBar = [[UIView alloc] initWithFrame:CGRectZero];
    self.topBar.backgroundColor = RXBackgroundColor();
    self.topBar.translatesAutoresizingMaskIntoConstraints = NO;

    [self.rootView addSubview:self.topBar];

    self.brandLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.brandLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.brandLabel.text = @"radix";
    self.brandLabel.textColor = RXAccentColor();
    self.brandLabel.font = [UIFont systemFontOfSize:31 weight:UIFontWeightHeavy];
    self.brandLabel.adjustsFontSizeToFitWidth = YES;

    [self.topBar addSubview:self.brandLabel];

    UILabel *editionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    editionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    editionLabel.text = @"PACKAGE MANAGER";
    editionLabel.textColor = RXSecondaryTextColor();
    editionLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBold];

    [self.topBar addSubview:editionLabel];

    self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.refreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.refreshButton setImage:[UIImage systemImageNamed:@"arrow.clockwise"]
                        forState:UIControlStateNormal];
    self.refreshButton.tintColor = RXPrimaryTextColor();
    self.refreshButton.backgroundColor = RXCardColor();
    self.refreshButton.layer.cornerRadius = 17.0;
    self.refreshButton.accessibilityLabel = @"Refresh repositories";
    [self.refreshButton addTarget:self
                           action:@selector(refreshButtonPressed)
                 forControlEvents:UIControlEventTouchUpInside];

    [self.topBar addSubview:self.refreshButton];

    self.pageTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.pageTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageTitleLabel.textColor = RXPrimaryTextColor();
    self.pageTitleLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightBold];

    [self.topBar addSubview:self.pageTitleLabel];

    self.pageSubtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.pageSubtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageSubtitleLabel.textColor = RXSecondaryTextColor();
    self.pageSubtitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];

    [self.topBar addSubview:self.pageSubtitleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.topBar.topAnchor constraintEqualToAnchor:self.rootView.safeAreaLayoutGuide.topAnchor],
        [self.topBar.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor],
        [self.topBar.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor],
        [self.topBar.heightAnchor constraintEqualToConstant:112.0],

        [self.brandLabel.leadingAnchor constraintEqualToAnchor:self.topBar.leadingAnchor constant:22.0],
        [self.brandLabel.topAnchor constraintEqualToAnchor:self.topBar.topAnchor constant:3.0],

        [editionLabel.leadingAnchor constraintEqualToAnchor:self.brandLabel.trailingAnchor constant:9.0],
        [editionLabel.bottomAnchor constraintEqualToAnchor:self.brandLabel.bottomAnchor constant:-5.0],

        [self.refreshButton.trailingAnchor constraintEqualToAnchor:self.topBar.trailingAnchor constant:-22.0],
        [self.refreshButton.centerYAnchor constraintEqualToAnchor:self.brandLabel.centerYAnchor constant:2.0],
        [self.refreshButton.widthAnchor constraintEqualToConstant:36.0],
        [self.refreshButton.heightAnchor constraintEqualToConstant:36.0],

        [self.pageTitleLabel.leadingAnchor constraintEqualToAnchor:self.topBar.leadingAnchor constant:23.0],
        [self.pageTitleLabel.topAnchor constraintEqualToAnchor:self.brandLabel.bottomAnchor constant:4.0],

        [self.pageSubtitleLabel.leadingAnchor constraintEqualToAnchor:self.pageTitleLabel.leadingAnchor],
        [self.pageSubtitleLabel.topAnchor constraintEqualToAnchor:self.pageTitleLabel.bottomAnchor constant:2.0]
    ]];
}

- (void)buildContentArea {
    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.backgroundColor = RXBackgroundColor();

    [self.rootView addSubview:self.contentView];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search packages";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.barTintColor = RXBackgroundColor();
    self.searchBar.backgroundColor = RXBackgroundColor();
    self.searchBar.tintColor = RXAccentColor();
    self.searchBar.hidden = YES;

    UITextField *searchField = [self.searchBar.searchTextField isKindOfClass:[UITextField class]]
        ? self.searchBar.searchTextField
        : nil;

    if (searchField) {
        searchField.textColor = RXPrimaryTextColor();
        searchField.backgroundColor = RXCardColor();
        searchField.attributedPlaceholder = [[NSAttributedString alloc]
            initWithString:@"Search packages"
                attributes:@{
                    NSForegroundColorAttributeName: RXSecondaryTextColor()
                }];
    }

    [self.contentView addSubview:self.searchBar];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                 style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = RXBackgroundColor();
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 72, 0, 18);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 76.0;
    self.tableView.estimatedRowHeight = 76.0;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.contentInset = UIEdgeInsetsMake(4, 0, 12, 0);

    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"RadixPackageCell"];

    [self.contentView addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.topAnchor constraintEqualToAnchor:self.topBar.bottomAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor],

        [self.searchBar.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.searchBar.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12.0],
        [self.searchBar.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12.0],
        [self.searchBar.heightAnchor constraintEqualToConstant:52.0],

        [self.tableView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)buildBottomBar {
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectZero];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBar.backgroundColor = [UIColor colorWithRed:0.055
                                                    green:0.067
                                                     blue:0.098
                                                    alpha:1.0];

    UIView *topBorder = [[UIView alloc] initWithFrame:CGRectZero];
    topBorder.translatesAutoresizingMaskIntoConstraints = NO;
    topBorder.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.07];

    [self.bottomBar addSubview:topBorder];
    [self.rootView addSubview:self.bottomBar];

    NSArray<NSString *> *titles = @[
        @"Home",
        @"Packages",
        @"Sources",
        @"Queue",
        @"Installed"
    ];

    NSArray<NSString *> *symbols = @[
        @"house.fill",
        @"square.grid.2x2.fill",
        @"shippingbox.fill",
        @"arrow.down.circle.fill",
        @"checkmark.circle.fill"
    ];

    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];

    for (NSInteger index = 0; index < titles.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.tag = index;
        button.tintColor = RXSecondaryTextColor();
        button.titleLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightSemibold];

        UIImage *image = [UIImage systemImageNamed:symbols[index]];
        [button setImage:image forState:UIControlStateNormal];
        [button setTitle:titles[index] forState:UIControlStateNormal];

        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.adjustsFontSizeToFitWidth = YES;

        [button addTarget:self
                   action:@selector(tabButtonPressed:)
         forControlEvents:UIControlEventTouchUpInside];

        [self.bottomBar addSubview:button];
        [buttons addObject:button];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.bottomBar.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor],
        [self.bottomBar.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor],
        [self.bottomBar.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor],
        [self.bottomBar.heightAnchor constraintEqualToConstant:84.0],

        [topBorder.topAnchor constraintEqualToAnchor:self.bottomBar.topAnchor],
        [topBorder.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor],
        [topBorder.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor],
        [topBorder.heightAnchor constraintEqualToConstant:1.0]
    ]];

    UIButton *previousButton = nil;

    for (UIButton *button in buttons) {
        [NSLayoutConstraint activateConstraints:@[
            [button.topAnchor constraintEqualToAnchor:self.bottomBar.topAnchor constant:7.0],
            [button.bottomAnchor constraintEqualToAnchor:self.bottomBar.safeAreaLayoutGuide.bottomAnchor constant:-3.0]
        ]];

        if (previousButton) {
            [button.leadingAnchor constraintEqualToAnchor:previousButton.trailingAnchor].active = YES;
            [button.widthAnchor constraintEqualToAnchor:previousButton.widthAnchor].active = YES;
        } else {
            [button.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor].active = YES;
        }

        previousButton = button;
    }

    if (previousButton) {
        [previousButton.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor].active = YES;
    }

    [self updateTabButtonAppearance];
}

#pragma mark - Tab Navigation

- (void)tabButtonPressed:(UIButton *)sender {
    [self.view endEditing:YES];

    RXTab tab = (RXTab)sender.tag;
    [self showTab:tab];
}

- (void)showTab:(RXTab)tab {
    self.selectedTab = tab;

    self.searchBar.text = @"";
    self.isSearching = NO;
    [self updateTabButtonAppearance];

    switch (tab) {
        case RXTabHome:
            self.pageTitleLabel.text = @"Discover";
            self.pageSubtitleLabel.text = @"Your jailbreak package hub";
            self.searchBar.hidden = YES;
            self.refreshButton.hidden = NO;
            break;

        case RXTabPackages:
            self.pageTitleLabel.text = @"Packages";
            self.pageSubtitleLabel.text = [NSString stringWithFormat:@"%lu available",
                                           (unsigned long)self.packages.count];
            self.searchBar.hidden = NO;
            self.refreshButton.hidden = NO;
            break;

        case RXTabSources:
            self.pageTitleLabel.text = @"Sources";
            self.pageSubtitleLabel.text = @"Manage your repositories";
            self.searchBar.hidden = YES;
            self.refreshButton.hidden = NO;
            break;

        case RXTabQueue:
            self.pageTitleLabel.text = @"Queue";
            self.pageSubtitleLabel.text = @"Review package downloads";
            self.searchBar.hidden = YES;
            self.refreshButton.hidden = YES;
            break;

        case RXTabInstalled:
            self.pageTitleLabel.text = @"Downloaded";
            self.pageSubtitleLabel.text = @"Packages saved on this device";
            self.searchBar.hidden = YES;
            self.refreshButton.hidden = YES;
            break;
    }

    [self updateTableHeader];
    [self updateEmptyState];
    [self.tableView reloadData];
}

- (void)updateTabButtonAppearance {
    for (UIView *view in self.bottomBar.subviews) {
        if (![view isKindOfClass:[UIButton class]]) {
            continue;
        }

        UIButton *button = (UIButton *)view;
        BOOL selected = button.tag == self.selectedTab;

        button.tintColor = selected ? RXAccentColor() : RXSecondaryTextColor();
        [button setTitleColor:(selected ? RXAccentColor() : RXSecondaryTextColor())
                     forState:UIControlStateNormal];

        if (selected) {
            button.titleLabel.font = [UIFont systemFontOfSize:10.0
                                                       weight:UIFontWeightBold];
        } else {
            button.titleLabel.font = [UIFont systemFontOfSize:10.0
                                                       weight:UIFontWeightMedium];
        }
    }
}

#pragma mark - Table Headers

- (UIView *)makeSectionHeaderWithTitle:(NSString *)title
                              subtitle:(NSString *)subtitle {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 68.0)];
    container.backgroundColor = RXBackgroundColor();

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = title;
    titleLabel.textColor = RXPrimaryTextColor();
    titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];

    [container addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.text = subtitle;
    subtitleLabel.textColor = RXSecondaryTextColor();
    subtitleLabel.font = [UIFont systemFontOfSize:12.0];

    [container addSubview:subtitleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:22.0],
        [titleLabel.topAnchor constraintEqualToAnchor:container.topAnchor constant:12.0],

        [subtitleLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:3.0]
    ]];

    return container;
}

- (UIView *)makeHomeHeader {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 370.0)];
    container.backgroundColor = RXBackgroundColor();

    UIView *heroCard = [[UIView alloc] initWithFrame:CGRectZero];
    heroCard.translatesAutoresizingMaskIntoConstraints = NO;
    heroCard.backgroundColor = RXCardColor();
    heroCard.layer.cornerRadius = 23.0;
    heroCard.layer.borderWidth = 1.0;
    heroCard.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.045].CGColor;
    heroCard.clipsToBounds = YES;

    [container addSubview:heroCard];

    UIView *accentStrip = [[UIView alloc] initWithFrame:CGRectZero];
    accentStrip.translatesAutoresizingMaskIntoConstraints = NO;
    accentStrip.backgroundColor = RXAccentColor();

    [heroCard addSubview:accentStrip];

    UILabel *eyebrow = [[UILabel alloc] initWithFrame:CGRectZero];
    eyebrow.translatesAutoresizingMaskIntoConstraints = NO;
    eyebrow.text = @"WELCOME TO RADIX";
    eyebrow.textColor = RXAccentColor();
    eyebrow.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightBold];

    [heroCard addSubview:eyebrow];

    UILabel *heroTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    heroTitle.translatesAutoresizingMaskIntoConstraints = NO;
    heroTitle.text = @"Your packages.\\nYour way.";
    heroTitle.numberOfLines = 0;
    heroTitle.textColor = RXPrimaryTextColor();
    heroTitle.font = [UIFont systemFontOfSize:29.0 weight:UIFontWeightHeavy];

    [heroCard addSubview:heroTitle];

    UILabel *heroDescription = [[UILabel alloc] initWithFrame:CGRectZero];
    heroDescription.translatesAutoresizingMaskIntoConstraints = NO;
    heroDescription.text = @"Explore repositories and discover software for your device.";
    heroDescription.numberOfLines = 0;
    heroDescription.textColor = RXSecondaryTextColor();
    heroDescription.font = [UIFont systemFontOfSize:13.0];

    [heroCard addSubview:heroDescription];

    UIButton *browseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    browseButton.translatesAutoresizingMaskIntoConstraints = NO;
    browseButton.backgroundColor = RXAccentColor();
    browseButton.layer.cornerRadius = 12.0;
    browseButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    [browseButton setTitle:@"Explore packages  →" forState:UIControlStateNormal];
    [browseButton setTitleColor:RXBackgroundColor() forState:UIControlStateNormal];
    [browseButton addTarget:self
                     action:@selector(openPackages)
           forControlEvents:UIControlEventTouchUpInside];

    [heroCard addSubview:browseButton];

    UIView *statsCard = [[UIView alloc] initWithFrame:CGRectZero];
    statsCard.translatesAutoresizingMaskIntoConstraints = NO;
    statsCard.backgroundColor = RXCardColor();
    statsCard.layer.cornerRadius = 18.0;

    [container addSubview:statsCard];

    UILabel *repositoryCount = [[UILabel alloc] initWithFrame:CGRectZero];
    repositoryCount.translatesAutoresizingMaskIntoConstraints = NO;
    repositoryCount.text = [NSString stringWithFormat:@"%lu",
                            (unsigned long)self.sources.count];
    repositoryCount.textColor = RXPrimaryTextColor();
    repositoryCount.font = [UIFont systemFontOfSize:25.0 weight:UIFontWeightBold];

    [statsCard addSubview:repositoryCount];

    UILabel *repositoryCaption = [[UILabel alloc] initWithFrame:CGRectZero];
    repositoryCaption.translatesAutoresizingMaskIntoConstraints = NO;
    repositoryCaption.text = @"REPOSITORIES";
    repositoryCaption.textColor = RXSecondaryTextColor();
    repositoryCaption.font = [UIFont systemFontOfSize:9.0 weight:UIFontWeightBold];

    [statsCard addSubview:repositoryCaption];

    UIView *divider = [[UIView alloc] initWithFrame:CGRectZero];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];

    [statsCard addSubview:divider];

    UILabel *packageCount = [[UILabel alloc] initWithFrame:CGRectZero];
    packageCount.translatesAutoresizingMaskIntoConstraints = NO;
    packageCount.text = [NSString stringWithFormat:@"%lu",
                         (unsigned long)self.packages.count];
    packageCount.textColor = RXPrimaryTextColor();
    packageCount.font = [UIFont systemFontOfSize:25.0 weight:UIFontWeightBold];

    [statsCard addSubview:packageCount];

    UILabel *packageCaption = [[UILabel alloc] initWithFrame:CGRectZero];
    packageCaption.translatesAutoresizingMaskIntoConstraints = NO;
    packageCaption.text = @"PACKAGES";
    packageCaption.textColor = RXSecondaryTextColor();
    packageCaption.font = [UIFont systemFontOfSize:9.0 weight:UIFontWeightBold];

    [statsCard addSubview:packageCaption];

    UIButton *addSourceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    addSourceButton.translatesAutoresizingMaskIntoConstraints = NO;
    addSourceButton.backgroundColor = RXSecondaryColor();
    addSourceButton.layer.cornerRadius = 14.0;
    addSourceButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    addSourceButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    [addSourceButton setTitle:@"   ＋   Add a repository" forState:UIControlStateNormal];
    [addSourceButton setTitleColor:RXPrimaryTextColor() forState:UIControlStateNormal];
    [addSourceButton addTarget:self
                        action:@selector(addSourcePressed)
              forControlEvents:UIControlEventTouchUpInside];

    [container addSubview:addSourceButton];

    [NSLayoutConstraint activateConstraints:@[
        [heroCard.topAnchor constraintEqualToAnchor:container.topAnchor constant:12.0],
        [heroCard.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:18.0],
        [heroCard.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-18.0],
        [heroCard.heightAnchor constraintEqualToConstant:235.0],

        [accentStrip.topAnchor constraintEqualToAnchor:heroCard.topAnchor],
        [accentStrip.leadingAnchor constraintEqualToAnchor:heroCard.leadingAnchor],
        [accentStrip.widthAnchor constraintEqualToConstant:4.0],
        [accentStrip.bottomAnchor constraintEqualToAnchor:heroCard.bottomAnchor],

        [eyebrow.leadingAnchor constraintEqualToAnchor:heroCard.leadingAnchor constant:23.0],
        [eyebrow.topAnchor constraintEqualToAnchor:heroCard.topAnchor constant:21.0],

        [heroTitle.leadingAnchor constraintEqualToAnchor:eyebrow.leadingAnchor],
        [heroTitle.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:13.0],

        [heroDescription.leadingAnchor constraintEqualToAnchor:heroTitle.leadingAnchor],
        [heroDescription.trailingAnchor constraintEqualToAnchor:heroCard.trailingAnchor constant:-20.0],
        [heroDescription.topAnchor constraintEqualToAnchor:heroTitle.bottomAnchor constant:8.0],

        [browseButton.leadingAnchor constraintEqualToAnchor:heroTitle.leadingAnchor],
        [browseButton.bottomAnchor constraintEqualToAnchor:heroCard.bottomAnchor constant:-17.0],
        [browseButton.heightAnchor constraintEqualToConstant:40.0],
        [browseButton.widthAnchor constraintEqualToConstant:185.0],

        [statsCard.topAnchor constraintEqualToAnchor:heroCard.bottomAnchor constant:13.0],
        [statsCard.leadingAnchor constraintEqualToAnchor:heroCard.leadingAnchor],
        [statsCard.trailingAnchor constraintEqualToAnchor:heroCard.trailingAnchor],
        [statsCard.heightAnchor constraintEqualToConstant:77.0],

        [repositoryCount.leadingAnchor constraintEqualToAnchor:statsCard.leadingAnchor constant:19.0],
        [repositoryCount.centerYAnchor constraintEqualToAnchor:statsCard.centerYAnchor constant:-5.0],

        [repositoryCaption.leadingAnchor constraintEqualToAnchor:repositoryCount.leadingAnchor],
        [repositoryCaption.topAnchor constraintEqualToAnchor:repositoryCount.bottomAnchor constant:0.0],

        [divider.centerXAnchor constraintEqualToAnchor:statsCard.centerXAnchor],
        [divider.topAnchor constraintEqualToAnchor:statsCard.topAnchor constant:17.0],
        [divider.bottomAnchor constraintEqualToAnchor:statsCard.bottomAnchor constant:-17.0],
        [divider.widthAnchor constraintEqualToConstant:1.0],

        [packageCount.leadingAnchor constraintEqualToAnchor:divider.trailingAnchor constant:22.0],
        [packageCount.centerYAnchor constraintEqualToAnchor:repositoryCount.centerYAnchor],

        [packageCaption.leadingAnchor constraintEqualToAnchor:packageCount.leadingAnchor],
        [packageCaption.topAnchor constraintEqualToAnchor:packageCount.bottomAnchor],

        [addSourceButton.topAnchor constraintEqualToAnchor:statsCard.bottomAnchor constant:12.0],
        [addSourceButton.leadingAnchor constraintEqualToAnchor:heroCard.leadingAnchor],
        [addSourceButton.trailingAnchor constraintEqualToAnchor:heroCard.trailingAnchor],
        [addSourceButton.heightAnchor constraintEqualToConstant:47.0]
    ]];

    return container;
}

- (void)updateTableHeader {
    UIView *header = nil;

    switch (self.selectedTab) {
        case RXTabHome:
            header = [self makeHomeHeader];
            break;

        case RXTabPackages:
            header = [self makeSectionHeaderWithTitle:@"Explore"
                                             subtitle:@"Browse software from your configured sources."];
            break;

        case RXTabSources: {
            UIView *container = [self makeSectionHeaderWithTitle:@"Your repositories"
                                                        subtitle:@"Repository indexes provide package information."];

            UIButton *addButton = [UIButton buttonWithType:UIButtonTypeSystem];
            addButton.frame = CGRectMake(0, 0, 0, 0);
            addButton.translatesAutoresizingMaskIntoConstraints = NO;
            addButton.backgroundColor = RXAccentColor();
            addButton.layer.cornerRadius = 10.0;
            [addButton setTitle:@"＋ Add Source" forState:UIControlStateNormal];
            [addButton setTitleColor:RXBackgroundColor() forState:UIControlStateNormal];
            addButton.titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
            [addButton addTarget:self
                          action:@selector(addSourcePressed)
                forControlEvents:UIControlEventTouchUpInside];

            [container addSubview:addButton];

            [NSLayoutConstraint activateConstraints:@[
                [addButton.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-20.0],
                [addButton.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
                [addButton.widthAnchor constraintEqualToConstant:112.0],
                [addButton.heightAnchor constraintEqualToConstant:34.0]
            ]];

            header = container;
            break;
        }

        case RXTabQueue:
            header = [self makeSectionHeaderWithTitle:@"Download queue"
                                             subtitle:@"Downloads are saved inside Radix's app storage."];
            break;

        case RXTabInstalled:
            header = [self makeSectionHeaderWithTitle:@"Downloaded packages"
                                             subtitle:@"Downloaded files are not the same as installed packages."];
            break;
    }

    self.tableView.tableHeaderView = header;
}

#pragma mark - Empty States

- (void)updateEmptyState {
    NSString *message = nil;
    NSString *detail = nil;
    NSString *symbol = nil;

    switch (self.selectedTab) {
        case RXTabHome:
            if (self.packages.count == 0) {
                message = @"Nothing to explore yet";
                detail = @"Add a repository to discover available packages.";
                symbol = @"shippingbox";
            }
            break;

        case RXTabPackages:
            if (self.filteredPackages.count == 0) {
                message = self.packages.count == 0 ? @"No packages yet" : @"No matching packages";
                detail = self.packages.count == 0
                    ? @"Add a repository, then refresh its package index."
                    : @"Try another search term.";
                symbol = @"magnifyingglass";
            }
            break;

        case RXTabSources:
            if (self.sources.count == 0) {
                message = @"No repositories";
                detail = @"Add a repository index URL to get started.";
                symbol = @"shippingbox";
            }
            break;

        case RXTabQueue:
            if (self.downloadQueue.count == 0) {
                message = @"Queue is empty";
                detail = @"Open a package and choose Download to add it here.";
                symbol = @"arrow.down.to.line";
            }
            break;

        case RXTabInstalled:
            if (self.downloadedPackages.count == 0) {
                message = @"Nothing downloaded";
                detail = @"Packages you download will appear here.";
                symbol = @"checkmark.circle";
            }
            break;
    }

    if (!message) {
        self.tableView.backgroundView = nil;
        return;
    }

    UIView *emptyView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    emptyView.backgroundColor = RXBackgroundColor();

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:symbol]];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.tintColor = RXAccentColor();
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    [emptyView addSubview:iconView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = message;
    titleLabel.textColor = RXPrimaryTextColor();
    titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
    titleLabel.textAlignment = NSTextAlignmentCenter;

    [emptyView addSubview:titleLabel];

    UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    detailLabel.text = detail;
    detailLabel.textColor = RXSecondaryTextColor();
    detailLabel.font = [UIFont systemFontOfSize:12.0];
    detailLabel.numberOfLines = 0;
    detailLabel.textAlignment = NSTextAlignmentCenter;

    [emptyView addSubview:detailLabel];

    [NSLayoutConstraint activateConstraints:@[
        [iconView.centerXAnchor constraintEqualToAnchor:emptyView.centerXAnchor],
        [iconView.centerYAnchor constraintEqualToAnchor:emptyView.centerYAnchor constant:-42.0],
        [iconView.widthAnchor constraintEqualToConstant:36.0],
        [iconView.heightAnchor constraintEqualToConstant:36.0],

        [titleLabel.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:17.0],
        [titleLabel.leadingAnchor constraintEqualToAnchor:emptyView.leadingAnchor constant:25.0],
        [titleLabel.trailingAnchor constraintEqualToAnchor:emptyView.trailingAnchor constant:-25.0],

        [detailLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:7.0],
        [detailLabel.leadingAnchor constraintEqualToAnchor:emptyView.leadingAnchor constant:38.0],
        [detailLabel.trailingAnchor constraintEqualToAnchor:emptyView.trailingAnchor constant:-38.0]
    ]];

    self.tableView.backgroundView = emptyView;
}

#pragma mark - Actions

- (void)openPackages {
    [self showTab:RXTabPackages];
}

- (void)refreshButtonPressed {
    if (self.selectedTab == RXTabSources) {
        [self refreshAllSources];
        return;
    }

    if (self.sources.count == 0) {
        [self showTab:RXTabSources];
        [self addSourcePressed];
        return;
    }

    [self refreshAllSources];
}

#pragma mark - Repository Management

- (void)addSourcePressed {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Add Repository"
                         message:@"Enter a direct URL to a Debian Packages index file. For example, a repository's Packages file—not just its homepage."
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"https://example.com/Packages";
        textField.keyboardType = UIKeyboardTypeURL;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];

    __weak typeof(self) weakSelf = self;

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Add"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        NSString *rawURL = [alert.textFields.firstObject.text
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        NSURLComponents *components = [NSURLComponents componentsWithString:rawURL];

        BOOL validScheme = [components.scheme.lowercaseString isEqualToString:@"https"] ||
                           [components.scheme.lowercaseString isEqualToString:@"http"];

        if (!components || !validScheme || components.host.length == 0) {
            [strongSelf showMessage:@"Invalid URL"
                            message:@"Enter a valid HTTP or HTTPS repository index URL."];
            return;
        }

        NSURL *url = components.URL;
        if (!url) {
            [strongSelf showMessage:@"Invalid URL"
                            message:@"Radix couldn't interpret that URL."];
            return;
        }

        NSString *absoluteString = url.absoluteString;

        for (NSDictionary *existingSource in strongSelf.sources) {
            if ([existingSource[@"url"] isEqualToString:absoluteString]) {
                [strongSelf showMessage:@"Repository already added"
                                message:@"That repository URL is already in your source list."];
                return;
            }
        }

        NSString *name = url.lastPathComponent.length > 0
            ? url.lastPathComponent
            : url.host;

        NSDictionary *source = @{
            @"name": name ?: @"Repository",
            @"url": absoluteString,
            @"status": @"Not refreshed"
        };

        [strongSelf.sources addObject:source];
        [strongSelf saveSources];
        [strongSelf showTab:RXTabSources];
        [strongSelf refreshSource:source];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)refreshAllSources {
    if (self.isRefreshing) {
        return;
    }

    if (self.sources.count == 0) {
        [self showMessage:@"No repositories"
                  message:@"Add a repository before refreshing package indexes."];
        [self showTab:RXTabSources];
        return;
    }

    for (NSDictionary *source in [self.sources copy]) {
        [self refreshSource:source];
    }
}

- (void)refreshSource:(NSDictionary *)source {
    NSString *urlString = source[@"url"];

    if (![urlString isKindOfClass:[NSString class]]) {
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 45.0;
    [request setValue:@"Radix/1.0" forHTTPHeaderField:@"User-Agent"];

    self.isRefreshing = YES;
    [self.refreshButton setImage:[UIImage systemImageNamed:@"arrow.clockwise"]
                        forState:UIControlStateNormal];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
        dataTaskWithRequest:request
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if (error || !data || (httpResponse && httpResponse.statusCode >= 400)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateSource:source
                            status:(error.localizedDescription ?: @"Unable to load index")];

                self.isRefreshing = NO;
                [self.tableView reloadData];
                [self updateEmptyState];

                [self showMessage:@"Repository refresh failed"
                          message:error.localizedDescription ?: @"The server returned an unsuccessful response."];
            });
            return;
        }

        NSString *contents = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];

        if (!contents) {
            contents = [[NSString alloc] initWithData:data
                                              encoding:NSISOLatin1StringEncoding];
        }

        if (!contents) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateSource:source status:@"Index is not readable text"];
                self.isRefreshing = NO;
                [self.tableView reloadData];

                [self showMessage:@"Unsupported index"
                          message:@"The repository response could not be decoded as a Debian package index."];
            });
            return;
        }

        NSArray<NSDictionary *> *parsedPackages = [self parsePackagesIndex:contents
                                                                  sourceURL:url];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self mergePackages:parsedPackages];

            [self updateSource:source
                        status:[NSString stringWithFormat:@"%lu packages",
                                (unsigned long)parsedPackages.count]];

            self.isRefreshing = NO;

            [self updateTabSubtitle];
            [self updateTableHeader];
            [self updateEmptyState];
            [self.tableView reloadData];

            if (self.selectedTab == RXTabSources) {
                [self showMessage:@"Repository refreshed"
                          message:[NSString stringWithFormat:@"Read %lu package records.",
                                   (unsigned long)parsedPackages.count]];
            }
        });
    }];

    [task resume];
}

- (void)updateSource:(NSDictionary *)source status:(NSString *)status {
    NSString *sourceURL = source[@"url"];
    if (![sourceURL isKindOfClass:[NSString class]]) {
        return;
    }

    NSInteger index = NSNotFound;

    for (NSInteger i = 0; i < self.sources.count; i++) {
        if ([self.sources[i][@"url"] isEqualToString:sourceURL]) {
            index = i;
            break;
        }
    }

    if (index == NSNotFound) {
        return;
    }

    NSMutableDictionary *updated = [self.sources[index] mutableCopy];
    updated[@"status"] = status ?: @"Unknown status";
    self.sources[index] = updated;

    [self saveSources];
}

- (void)removeSourceAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.sources.count) {
        return;
    }

    NSDictionary *source = self.sources[index];
    NSString *sourceURL = source[@"url"];

    [self.sources removeObjectAtIndex:index];

    NSIndexSet *indexesToRemove = [self.packages indexesOfObjectsPassingTest:
        ^BOOL(NSDictionary *package, NSUInteger idx, BOOL *stop) {
            return [package[@"RepositoryURL"] isEqualToString:sourceURL];
        }];

    [self.packages removeObjectsAtIndexes:indexesToRemove];

    [self rebuildFilteredPackages];
    [self saveSources];

    [self updateTabSubtitle];
    [self updateTableHeader];
    [self updateEmptyState];
    [self.tableView reloadData];
}

#pragma mark - Debian Package Index Parsing

- (NSArray<NSDictionary *> *)parsePackagesIndex:(NSString *)contents
                                      sourceURL:(NSURL *)sourceURL {
    NSMutableArray<NSDictionary *> *result = [NSMutableArray array];

    NSMutableDictionary *currentPackage = [NSMutableDictionary dictionary];
    NSMutableString *currentContinuation = nil;

    NSArray<NSString *> *lines = [contents componentsSeparatedByCharactersInSet:
                                  [NSCharacterSet newlineCharacterSet]];

    for (NSString *line in lines) {
        if (line.length == 0) {
            if (currentPackage[@"Package"]) {
                NSMutableDictionary *package = [currentPackage mutableCopy];

                package[@"RepositoryURL"] = sourceURL.absoluteString ?: @"";
                package[@"Name"] = package[@"Package"] ?: @"Unknown package";
                package[@"Version"] = package[@"Version"] ?: @"Unknown";
                package[@"Description"] = package[@"Description"] ?: @"No description provided.";
                package[@"Section"] = package[@"Section"] ?: @"Other";
                package[@"Architecture"] = package[@"Architecture"] ?: @"Unknown";

                [result addObject:package];
            }

            [currentPackage removeAllObjects];
            currentContinuation = nil;
            continue;
        }

        if ([line hasPrefix:@" "] || [line hasPrefix:@"\t"]) {
            if (currentContinuation) {
                [currentContinuation appendFormat:@"\n%@", [line stringByTrimmingCharactersInSet:
                                                            [NSCharacterSet whitespaceCharacterSet]]];
            }
            continue;
        }

        NSRange separator = [line rangeOfString:@":"];
        if (separator.location == NSNotFound || separator.location == 0) {
            currentContinuation = nil;
            continue;
        }

        NSString *key = [[line substringToIndex:separator.location]
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        NSString *value = [[line substringFromIndex:separator.location + 1]
                           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        currentPackage[key] = value;

        if ([key isEqualToString:@"Description"]) {
            currentContinuation = [NSMutableString stringWithString:value];
        } else {
            currentContinuation = nil;
        }
    }

    if (currentPackage[@"Package"]) {
        NSMutableDictionary *package = [currentPackage mutableCopy];

        package[@"RepositoryURL"] = sourceURL.absoluteString ?: @"";
        package[@"Name"] = package[@"Package"] ?: @"Unknown package";
        package[@"Version"] = package[@"Version"] ?: @"Unknown";
        package[@"Description"] = package[@"Description"] ?: @"No description provided.";
        package[@"Section"] = package[@"Section"] ?: @"Other";
        package[@"Architecture"] = package[@"Architecture"] ?: @"Unknown";

        [result addObject:package];
    }

    return result;
}

- (void)mergePackages:(NSArray<NSDictionary *> *)newPackages {
    for (NSDictionary *package in newPackages) {
        NSString *name = package[@"Name"] ?: @"";
        NSString *version = package[@"Version"] ?: @"";
        NSString *repository = package[@"RepositoryURL"] ?: @"";

        NSInteger existingIndex = NSNotFound;

        for (NSInteger i = 0; i < self.packages.count; i++) {
            NSDictionary *existing = self.packages[i];

            if ([existing[@"Name"] isEqualToString:name] &&
                [existing[@"Version"] isEqualToString:version] &&
                [existing[@"RepositoryURL"] isEqualToString:repository]) {
                existingIndex = i;
                break;
            }
        }

        if (existingIndex == NSNotFound) {
            [self.packages addObject:package];
        } else {
            self.packages[existingIndex] = package;
        }
    }

    [self rebuildFilteredPackages];
}

- (void)rebuildFilteredPackages {
    NSString *query = self.searchBar.text ?: @"";
    NSString *trimmedQuery = [query stringByTrimmingCharactersInSet:
                              [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (trimmedQuery.length == 0) {
        self.filteredPackages = [self.packages mutableCopy];
        return;
    }

    NSMutableArray *results = [NSMutableArray array];

    for (NSDictionary *package in self.packages) {
        NSString *name = package[@"Name"] ?: @"";
        NSString *description = package[@"Description"] ?: @"";
        NSString *section = package[@"Section"] ?: @"";

        if ([name localizedCaseInsensitiveContainsString:trimmedQuery] ||
            [description localizedCaseInsensitiveContainsString:trimmedQuery] ||
            [section localizedCaseInsensitiveContainsString:trimmedQuery]) {
            [results addObject:package];
        }
    }

    self.filteredPackages = results;
}

#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.isSearching = searchText.length > 0;

    [self rebuildFilteredPackages];
    [self updateEmptyState];
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - Package Details

- (void)showPackageDetails:(NSDictionary *)package {
    NSString *name = package[@"Name"] ?: @"Unknown package";
    NSString *version = package[@"Version"] ?: @"Unknown";
    NSString *description = package[@"Description"] ?: @"No description provided.";
    NSString *section = package[@"Section"] ?: @"Other";
    NSString *architecture = package[@"Architecture"] ?: @"Unknown";
    NSString *size = package[@"Size"] ?: @"Unknown";
    NSString *maintainer = package[@"Maintainer"] ?: @"Unknown";
    NSString *filename = package[@"Filename"] ?: @"Unavailable";

    NSString *details = [NSString stringWithFormat:
                         @"%@\n\nVersion: %@\nSection: %@\nArchitecture: %@\nSize: %@\nMaintainer: %@\n\nFile: %@",
                         description,
                         version,
                         section,
                         architecture,
                         size,
                         maintainer,
                         filename];

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:name
                         message:details
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Close"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Download"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self enqueueDownloadForPackage:package];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Download Queue

- (void)enqueueDownloadForPackage:(NSDictionary *)package {
    NSString *name = package[@"Name"] ?: @"Unknown package";

    for (NSDictionary *queued in self.downloadQueue) {
        if ([queued[@"Name"] isEqualToString:name] &&
            [queued[@"Version"] isEqualToString:package[@"Version"]]) {
            [self showMessage:@"Already queued"
                      message:[NSString stringWithFormat:@"%@ is already in the download queue.", name]];
            return;
        }
    }

    for (NSDictionary *downloaded in self.downloadedPackages) {
        if ([downloaded[@"Name"] isEqualToString:name] &&
            [downloaded[@"Version"] isEqualToString:package[@"Version"]]) {
            [self showMessage:@"Already downloaded"
                      message:[NSString stringWithFormat:@"%@ is already saved in Radix.", name]];
            return;
        }
    }

    NSMutableDictionary *queueItem = [package mutableCopy];
    queueItem[@"DownloadStatus"] = @"Waiting";
    [self.downloadQueue addObject:queueItem];

    [self updateEmptyState];
    [self.tableView reloadData];

    [self showTab:RXTabQueue];
    [self startNextDownload];
}

- (void)startNextDownload {
    for (NSDictionary *item in [self.downloadQueue copy]) {
        NSString *name = item[@"Name"] ?: @"Unknown package";
        NSString *key = [self downloadKeyForPackage:item];

        if (self.activeDownloads[key]) {
            continue;
        }

        NSString *filename = item[@"Filename"];
        NSString *repositoryURL = item[@"RepositoryURL"];

        if (![filename isKindOfClass:[NSString class]] || filename.length == 0 ||
            ![repositoryURL isKindOfClass:[NSString class]] || repositoryURL.length == 0) {
            [self updateQueueItem:item status:@"Missing download URL"];
            continue;
        }

        NSURL *repositoryIndexURL = [NSURL URLWithString:repositoryURL];
        NSURL *downloadURL = nil;

        if ([filename hasPrefix:@"http://"] || [filename hasPrefix:@"https://"]) {
            downloadURL = [NSURL URLWithString:filename];
        } else if (repositoryIndexURL) {
            downloadURL = [NSURL URLWithString:filename
                                relativeToURL:repositoryIndexURL];
        }

        if (!downloadURL || !downloadURL.scheme.length) {
            [self updateQueueItem:item status:@"Invalid download URL"];
            continue;
        }

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downloadURL];
        request.timeoutInterval = 120.0;
        [request setValue:@"Radix/1.0" forHTTPHeaderField:@"User-Agent"];

        [self updateQueueItem:item status:@"Downloading"];

        __weak typeof(self) weakSelf = self;

        NSURLSessionDownloadTask *task = [[NSURLSession sharedSession]
            downloadTaskWithRequest:request
                  completionHandler:^(NSURL *location,
                                      NSURLResponse *response,
                                      NSError *error) {

            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.activeDownloads removeObjectForKey:key];

                if (error || !location ||
                    (httpResponse && httpResponse.statusCode >= 400)) {
                    [strongSelf updateQueueItem:item status:@"Download failed"];
                    [strongSelf showMessage:@"Download failed"
                                    message:error.localizedDescription ?: @"The server returned an unsuccessful response."];
                    [strongSelf.tableView reloadData];
                    [strongSelf updateEmptyState];
                    return;
                }

                NSString *safeName = [name stringByReplacingOccurrencesOfString:@"/"
                                                                     withString:@"_"];

                NSString *version = item[@"Version"] ?: @"unknown";
                NSString *safeVersion = [version stringByReplacingOccurrencesOfString:@"/"
                                                                           withString:@"_"];

                NSString *destinationName = [NSString stringWithFormat:@"%@_%@.deb",
                                             safeName, safeVersion];

                NSURL *documentsURL = [[[NSFileManager defaultManager]
                    URLsForDirectory:NSDocumentDirectory
                           inDomains:NSUserDomainMask] firstObject];

                NSURL *downloadsURL = [documentsURL URLByAppendingPathComponent:@"RadixDownloads"
                                                                    isDirectory:YES];

                NSError *directoryError = nil;

                [[NSFileManager defaultManager]
                    createDirectoryAtURL:downloadsURL
             withIntermediateDirectories:YES
                              attributes:nil
                                   error:&directoryError];

                if (directoryError) {
                    [strongSelf updateQueueItem:item status:@"Save failed"];
                    [strongSelf showMessage:@"Couldn't save package"
                                    message:directoryError.localizedDescription];
                    [strongSelf.tableView reloadData];
                    return;
                }

                NSURL *destinationURL = [downloadsURL URLByAppendingPathComponent:destinationName];

                NSError *removeError = nil;
                if ([[NSFileManager defaultManager] fileExistsAtPath:destinationURL.path]) {
                    [[NSFileManager defaultManager] removeItemAtURL:destinationURL
                                                              error:&removeError];
                }

                NSError *moveError = nil;
                BOOL moved = [[NSFileManager defaultManager]
                    moveItemAtURL:location
                            toURL:destinationURL
                            error:&moveError];

                if (!moved) {
                    [strongSelf updateQueueItem:item status:@"Save failed"];
                    [strongSelf showMessage:@"Couldn't save package"
                                    message:moveError.localizedDescription ?: @"The downloaded file could not be moved."];
                    [strongSelf.tableView reloadData];
                    return;
                }

                NSMutableDictionary *downloaded = [item mutableCopy];
                downloaded[@"LocalPath"] = destinationURL.path;
                downloaded[@"DownloadedAt"] = [NSDate date].description;
                downloaded[@"DownloadStatus"] = @"Downloaded";

                [strongSelf.downloadedPackages addObject:downloaded];
                [strongSelf saveDownloadedPackages];

                [strongSelf.downloadQueue removeObjectIdenticalTo:item];

                [strongSelf updateTableHeader];
                [strongSelf updateEmptyState];
                [strongSelf.tableView reloadData];

                [strongSelf showMessage:@"Download complete"
                                message:[NSString stringWithFormat:@"%@ was saved to Radix's app storage. It has not been installed.", name]];

                [strongSelf startNextDownload];
            });
        }];

        self.activeDownloads[key] = task;
        [task resume];

        // Keep downloads sequential to make queue status predictable.
        break;
    }

    [self updateTableHeader];
    [self.tableView reloadData];
}

- (NSString *)downloadKeyForPackage:(NSDictionary *)package {
    return [NSString stringWithFormat:@"%@|%@|%@",
            package[@"Name"] ?: @"",
            package[@"Version"] ?: @"",
            package[@"RepositoryURL"] ?: @""];
}

- (void)updateQueueItem:(NSDictionary *)item status:(NSString *)status {
    NSUInteger index = [self.downloadQueue indexOfObjectIdenticalTo:item];

    if (index == NSNotFound) {
        return;
    }

    NSMutableDictionary *updated = [item mutableCopy];
    updated[@"DownloadStatus"] = status ?: @"Unknown";
    self.downloadQueue[index] = updated;

    [self.tableView reloadData];
}

- (void)removeQueueItemAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.downloadQueue.count) {
        return;
    }

    NSDictionary *item = self.downloadQueue[index];
    NSString *key = [self downloadKeyForPackage:item];

    NSURLSessionDownloadTask *task = self.activeDownloads[key];

    if (task) {
        [task cancel];
        [self.activeDownloads removeObjectForKey:key];
    }

    [self.downloadQueue removeObjectAtIndex:index];

    [self updateEmptyState];
    [self.tableView reloadData];
    [self startNextDownload];
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    switch (self.selectedTab) {
        case RXTabHome:
        case RXTabPackages:
            return self.filteredPackages.count;

        case RXTabSources:
            return self.sources.count;

        case RXTabQueue:
            return self.downloadQueue.count;

        case RXTabInstalled:
            return self.downloadedPackages.count;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RadixPackageCell"
                                                            forIndexPath:indexPath];

    cell.backgroundColor = RXBackgroundColor();
    cell.contentView.backgroundColor = RXBackgroundColor();
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.imageView.image = nil;
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;

    // Use a subtitle-style cell so both the package title and description are visible.
    if (cell.detailTextLabel == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"RadixPackageCell"];
    }

    cell.backgroundColor = RXBackgroundColor();
    cell.textLabel.textColor = RXPrimaryTextColor();
    cell.textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    cell.textLabel.numberOfLines = 1;

    cell.detailTextLabel.textColor = RXSecondaryTextColor();
    cell.detailTextLabel.font = [UIFont systemFontOfSize:11.0];
    cell.detailTextLabel.numberOfLines = 2;

    cell.imageView.tintColor = RXAccentColor();
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;

    switch (self.selectedTab) {
        case RXTabHome:
        case RXTabPackages: {
            NSDictionary *package = self.filteredPackages[indexPath.row];

            cell.textLabel.text = package[@"Name"] ?: @"Unknown package";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  ·  %@",
                                         package[@"Version"] ?: @"Unknown version",
                                         package[@"Description"] ?: @"No description"];

            cell.imageView.image = [UIImage systemImageNamed:@"shippingbox.fill"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }

        case RXTabSources: {
            NSDictionary *source = self.sources[indexPath.row];

            cell.textLabel.text = source[@"name"] ?: @"Repository";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@",
                                         source[@"url"] ?: @"",
                                         source[@"status"] ?: @"Not refreshed"];

            cell.detailTextLabel.numberOfLines = 2;
            cell.imageView.image = [UIImage systemImageNamed:@"shippingbox.fill"];
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
            break;
        }

        case RXTabQueue: {
            NSDictionary *item = self.downloadQueue[indexPath.row];

            cell.textLabel.text = item[@"Name"] ?: @"Unknown package";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  ·  %@",
                                         item[@"Version"] ?: @"Unknown version",
                                         item[@"DownloadStatus"] ?: @"Waiting"];

            NSString *status = item[@"DownloadStatus"] ?: @"Waiting";
            cell.imageView.image = [UIImage systemImageNamed:
                                    [status isEqualToString:@"Downloading"]
                                    ? @"arrow.down.circle.fill"
                                    : @"clock.fill"];

            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }

        case RXTabInstalled: {
            NSDictionary *item = self.downloadedPackages[indexPath.row];

            cell.textLabel.text = item[@"Name"] ?: @"Unknown package";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  ·  Downloaded",
                                         item[@"Version"] ?: @"Unknown version"];

            cell.imageView.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
            cell.imageView.tintColor = RXAccentColor();
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView
 didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (self.selectedTab) {
        case RXTabHome:
        case RXTabPackages:
            if (indexPath.row < self.filteredPackages.count) {
                [self showPackageDetails:self.filteredPackages[indexPath.row]];
            }
            break;

        case RXTabSources:
            if (indexPath.row < self.sources.count) {
                [self showSourceActionsForIndex:indexPath.row];
            }
            break;

        case RXTabQueue:
            if (indexPath.row < self.downloadQueue.count) {
                NSDictionary *item = self.downloadQueue[indexPath.row];

                [self showMessage:item[@"Name"] ?: @"Queued package"
                          message:item[@"DownloadStatus"] ?: @"Waiting"];
            }
            break;

        case RXTabInstalled:
            if (indexPath.row < self.downloadedPackages.count) {
                NSDictionary *item = self.downloadedPackages[indexPath.row];

                NSString *path = item[@"LocalPath"] ?: @"Unavailable";
                NSString *message = [NSString stringWithFormat:
                                     @"Version: %@\n\nSaved file:\n%@\n\nThis package has been downloaded, but has not been installed.",
                                     item[@"Version"] ?: @"Unknown",
                                     path];

                [self showMessage:item[@"Name"] ?: @"Downloaded package"
                          message:message];
            }
            break;
    }
}

- (void)tableView:(UITableView *)tableView
 accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedTab == RXTabSources && indexPath.row < self.sources.count) {
        [self showSourceActionsForIndex:indexPath.row];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
 trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedTab == RXTabSources) {
        UIContextualAction *deleteAction = [UIContextualAction
            contextualActionWithStyle:UIContextualActionStyleDestructive
                                title:@"Remove"
                              handler:^(UIContextualAction *action,
                                        UIView *sourceView,
                                        void (^completionHandler)(BOOL)) {
            [self confirmRemoveSourceAtIndex:indexPath.row];
            completionHandler(YES);
        }];

        return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
    }

    if (self.selectedTab == RXTabQueue) {
        UIContextualAction *removeAction = [UIContextualAction
            contextualActionWithStyle:UIContextualActionStyleDestructive
                                title:@"Remove"
                              handler:^(UIContextualAction *action,
                                        UIView *sourceView,
                                        void (^completionHandler)(BOOL)) {
            [self removeQueueItemAtIndex:indexPath.row];
            completionHandler(YES);
        }];

        return [UISwipeActionsConfiguration configurationWithActions:@[removeAction]];
    }

    return nil;
}

#pragma mark - Source Actions

- (void)showSourceActionsForIndex:(NSInteger)index {
    if (index < 0 || index >= self.sources.count) {
        return;
    }

    NSDictionary *source = self.sources[index];

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:source[@"name"] ?: @"Repository"
                         message:source[@"url"] ?: @""
                  preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:@"Refresh"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self refreshSource:source];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Remove Repository"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [self confirmRemoveSourceAtIndex:index];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect =
            CGRectMake(CGRectGetMidX(self.view.bounds),
                       CGRectGetMidY(self.view.bounds),
                       1.0,
                       1.0);
    }

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmRemoveSourceAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.sources.count) {
        return;
    }

    NSDictionary *source = self.sources[index];

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Remove Repository?"
                         message:[NSString stringWithFormat:
                                  @"Remove %@ and its package entries from Radix?",
                                  source[@"name"] ?: @"this repository"]
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Remove"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [self removeSourceAtIndex:index];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Helpers

- (void)updateTabSubtitle {
    switch (self.selectedTab) {
        case RXTabHome:
            self.pageSubtitleLabel.text = @"Your jailbreak package hub";
            break;

        case RXTabPackages:
            self.pageSubtitleLabel.text = [NSString stringWithFormat:@"%lu available",
                                           (unsigned long)self.packages.count];
            break;

        case RXTabSources:
            self.pageSubtitleLabel.text = [NSString stringWithFormat:@"%lu repositories",
                                           (unsigned long)self.sources.count];
            break;

        case RXTabQueue:
            self.pageSubtitleLabel.text = [NSString stringWithFormat:@"%lu queued",
                                           (unsigned long)self.downloadQueue.count];
            break;

        case RXTabInstalled:
            self.pageSubtitleLabel.text = [NSString stringWithFormat:@"%lu downloaded",
                                           (unsigned long)self.downloadedPackages.count];
            break;
    }
}

- (void)showMessage:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title ?: @"Radix"
                         message:message ?: @""
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
