import Foundation
import UIKit

struct LibraryPicture: Identifiable, Hashable, Decodable {
    let name: String
    // Original pictures retain their emoji IDs. Expanded pictures use stable source IDs;
    // cards keep the optional libraryID separately so existing boards remain intact.
    let emoji: String
    let keywords: String
    let sourceID: String?
    init(name: String, emoji: String, keywords: String, sourceID: String? = nil) {
        self.name = name; self.emoji = emoji; self.keywords = keywords; self.sourceID = sourceID
    }
    var id: String { sourceID ?? emoji }
    var assetName: String { sourceID ?? PictureLibrary.assetName(for: emoji) }
}

enum PictureLibrary {
    private static let starterPictures: [LibraryPicture] = [
        .init(name: "Yes", emoji: "👍", keywords: "agree okay ok sure نعم"),
        .init(name: "No", emoji: "👎", keywords: "stop refuse disagree لا"),
        .init(name: "Help", emoji: "🙋", keywords: "assist assistance need help مساعدة"),
        .init(name: "A break", emoji: "🌿", keywords: "rest pause quiet break استراحة"),
        .init(name: "More", emoji: "➕", keywords: "again extra another more زيادة"),
        .init(name: "All done", emoji: "✅", keywords: "finished finish complete done انتهيت"),
        .init(name: "Apple", emoji: "🍎", keywords: "apples fruit snack red green تفاح"),
        .init(name: "Banana", emoji: "🍌", keywords: "bananas fruit snack موز"),
        .init(name: "Toast", emoji: "🍞", keywords: "bread sandwich toast خبز"),
        .init(name: "Pasta", emoji: "🍝", keywords: "spaghetti noodles meal pasta مكرونة"),
        .init(name: "Snack", emoji: "🥨", keywords: "pretzel pretzels snack وجبة خفيفة"),
        .init(name: "Hungry", emoji: "🍽️", keywords: "eat eating food meal hungry جوع جائع"),
        .init(name: "Water", emoji: "💧", keywords: "drink water ماء مياه"),
        .init(name: "Milk", emoji: "🥛", keywords: "drink milk حليب"),
        .init(name: "Juice", emoji: "🧃", keywords: "drink juice apple juice orange juice عصير"),
        .init(name: "Happy", emoji: "😊", keywords: "smile smiling glad happy سعيد"),
        .init(name: "Sad", emoji: "😢", keywords: "cry crying unhappy sad حزين"),
        .init(name: "Tired", emoji: "😴", keywords: "sleep sleepy nap tired نعسان متعب"),
        .init(name: "Too loud", emoji: "🎧", keywords: "noise noisy headphones loud صوت ضوضاء"),
        .init(name: "Hurt", emoji: "🩹", keywords: "pain painful ouch injury hurt ألم يؤلم"),
        .init(name: "A hug", emoji: "🫂", keywords: "cuddle comfort hug عناق"),
        .init(name: "Play", emoji: "🧸", keywords: "toy toys teddy bear play لعب"),
        .init(name: "Outside", emoji: "🌳", keywords: "tree park garden outdoor outside خارج حديقة"),
        .init(name: "Read", emoji: "📚", keywords: "book books story reading اقرأ كتاب"),
        .init(name: "Music", emoji: "🎵", keywords: "song songs sing singing music موسيقى"),
        .init(name: "Draw", emoji: "🎨", keywords: "paint painting coloring art draw رسم"),
        .init(name: "Bathroom", emoji: "🚽", keywords: "toilet potty restroom bathroom حمام"),
        .init(name: "Orange", emoji: "🍊", keywords: "oranges fruit snack برتقال"),
        .init(name: "Grapes", emoji: "🍇", keywords: "grape grapes fruit snack عنب"),
        .init(name: "Strawberry", emoji: "🍓", keywords: "strawberries berry fruit snack فراولة"),
        .init(name: "Watermelon", emoji: "🍉", keywords: "melon watermelon fruit snack بطيخ"),
        .init(name: "Pear", emoji: "🍐", keywords: "pears fruit snack كمثرى"),
        .init(name: "Peach", emoji: "🍑", keywords: "peaches fruit snack خوخ"),
        .init(name: "Pineapple", emoji: "🍍", keywords: "pineapple fruit snack أناناس"),
        .init(name: "Lemon", emoji: "🍋", keywords: "lemon fruit sour ليمون"),
        .init(name: "Carrot", emoji: "🥕", keywords: "carrots vegetable snack جزر"),
        .init(name: "Broccoli", emoji: "🥦", keywords: "vegetable broccoli خضار بروكلي"),
        .init(name: "Corn", emoji: "🌽", keywords: "vegetable corn ذرة"),
        .init(name: "Potato", emoji: "🥔", keywords: "potatoes vegetable بطاطس"),
        .init(name: "Tomato", emoji: "🍅", keywords: "tomatoes tomato طماطم"),
        .init(name: "Cucumber", emoji: "🥒", keywords: "cucumber vegetable خيار"),
        .init(name: "Egg", emoji: "🥚", keywords: "eggs egg breakfast بيض"),
        .init(name: "Cheese", emoji: "🧀", keywords: "cheese snack جبن"),
        .init(name: "Chicken", emoji: "🍗", keywords: "chicken food dinner دجاج"),
        .init(name: "Fish", emoji: "🐟", keywords: "fish سمك"),
        .init(name: "Rice", emoji: "🍚", keywords: "rice meal أرز"),
        .init(name: "Pizza", emoji: "🍕", keywords: "pizza meal بيتزا"),
        .init(name: "Sandwich", emoji: "🥪", keywords: "sandwich lunch ساندويتش"),
        .init(name: "Soup", emoji: "🍲", keywords: "soup stew meal شوربة"),
        .init(name: "Cookie", emoji: "🍪", keywords: "cookies biscuit biscuits sweet snack بسكويت"),
        .init(name: "Ice cream", emoji: "🍦", keywords: "ice cream dessert sweet مثلجات"),
        .init(name: "Cake", emoji: "🎂", keywords: "birthday cake dessert كعكة"),
        .init(name: "Chocolate", emoji: "🍫", keywords: "chocolate sweet snack شوكولاتة"),
        .init(name: "Yogurt", emoji: "🥣", keywords: "yogurt cereal bowl زبادي"),
        .init(name: "Popcorn", emoji: "🍿", keywords: "popcorn snack فشار"),
        .init(name: "Cup", emoji: "🥤", keywords: "cup drink tumbler كوب"),
        .init(name: "Bottle", emoji: "🍼", keywords: "bottle baby milk زجاجة"),
        .init(name: "Spoon", emoji: "🥄", keywords: "spoon utensil ملعقة"),
        .init(name: "Plate", emoji: "🍽", keywords: "plate dish صحن"),
        .init(name: "Brush teeth", emoji: "🪥", keywords: "brush teeth toothbrush toothpaste فرشاة أسنان"),
        .init(name: "Wash hands", emoji: "🧼", keywords: "wash hands soap clean صابون غسل"),
        .init(name: "Bath", emoji: "🛁", keywords: "bath tub bathing حمام استحمام"),
        .init(name: "Shower", emoji: "🚿", keywords: "shower washing دش"),
        .init(name: "Tissue", emoji: "🤧", keywords: "tissue sneeze nose منديل"),
        .init(name: "Bed", emoji: "🛏️", keywords: "bed bedroom bedtime sleep سرير"),
        .init(name: "Clothes", emoji: "👕", keywords: "clothes shirt tshirt dressing ملابس قميص"),
        .init(name: "Pants", emoji: "👖", keywords: "pants trousers jeans بنطلون"),
        .init(name: "Shoes", emoji: "👟", keywords: "shoes sneaker trainers حذاء"),
        .init(name: "Socks", emoji: "🧦", keywords: "socks جورب جوارب"),
        .init(name: "Coat", emoji: "🧥", keywords: "coat jacket cold معطف"),
        .init(name: "Hat", emoji: "🧢", keywords: "cap hat قبعة"),
        .init(name: "Backpack", emoji: "🎒", keywords: "backpack bag school حقيبة"),
        .init(name: "Home", emoji: "🏠", keywords: "house home منزل بيت"),
        .init(name: "School", emoji: "🏫", keywords: "school class classroom مدرسة"),
        .init(name: "Hospital", emoji: "🏥", keywords: "hospital doctor clinic مستشفى طبيب"),
        .init(name: "Car", emoji: "🚗", keywords: "car ride drive سيارة"),
        .init(name: "Bus", emoji: "🚌", keywords: "bus ride school bus حافلة"),
        .init(name: "Train", emoji: "🚆", keywords: "train ride قطار"),
        .init(name: "Airplane", emoji: "✈️", keywords: "plane airplane travel طائرة"),
        .init(name: "Bicycle", emoji: "🚲", keywords: "bike bicycle cycling دراجة"),
        .init(name: "Walk", emoji: "🚶", keywords: "walk walking move مشي"),
        .init(name: "Run", emoji: "🏃", keywords: "run running race جري"),
        .init(name: "Ball", emoji: "⚽", keywords: "ball football soccer كرة"),
        .init(name: "Swim", emoji: "🏊", keywords: "swim swimming pool سباحة"),
        .init(name: "Slide", emoji: "🛝", keywords: "playground slide park ملعب"),
        .init(name: "Puzzle", emoji: "🧩", keywords: "puzzle jigsaw game لغز"),
        .init(name: "Blocks", emoji: "🧱", keywords: "blocks build building bricks مكعبات"),
        .init(name: "Bubbles", emoji: "🫧", keywords: "bubbles play فقاعات"),
        .init(name: "TV", emoji: "📺", keywords: "tv television watch cartoon تلفزيون"),
        .init(name: "Tablet", emoji: "📱", keywords: "tablet ipad screen جهاز آيباد"),
        .init(name: "Camera", emoji: "📷", keywords: "camera photo picture كاميرا صورة"),
        .init(name: "Dog", emoji: "🐕", keywords: "dog puppy pet كلب"),
        .init(name: "Cat", emoji: "🐈", keywords: "cat kitten pet قطة"),
        .init(name: "Bird", emoji: "🐦", keywords: "bird pet عصفور"),
        .init(name: "Rabbit", emoji: "🐇", keywords: "rabbit bunny أرنب"),
        .init(name: "Horse", emoji: "🐎", keywords: "horse حصان"),
        .init(name: "Cow", emoji: "🐄", keywords: "cow بقرة"),
        .init(name: "Sheep", emoji: "🐑", keywords: "sheep خروف"),
        .init(name: "Hot", emoji: "🥵", keywords: "hot warm heat حار"),
        .init(name: "Cold", emoji: "🥶", keywords: "cold freezing chilly برد بارد"),
        .init(name: "Angry", emoji: "😠", keywords: "angry mad upset غاضب"),
        .init(name: "Scared", emoji: "😨", keywords: "scared afraid frightened خوف خائف"),
        .init(name: "Sick", emoji: "🤒", keywords: "sick ill fever مريض"),
        .init(name: "Confused", emoji: "😕", keywords: "confused unsure puzzled حيرة"),
        .init(name: "Love", emoji: "❤️", keywords: "love heart أحب حب"),
        .init(name: "Wait", emoji: "⏳", keywords: "wait waiting soon انتظر"),
        .init(name: "Listen", emoji: "👂", keywords: "listen hear hearing اسمع"),
        .init(name: "Look", emoji: "👀", keywords: "look see watch انظر"),
        .init(name: "Stop", emoji: "🛑", keywords: "stop halt قف توقف"),
        .init(name: "Go", emoji: "🟢", keywords: "go start اذهب ابدأ"),
        .init(name: "Please", emoji: "🙏", keywords: "please request thank thanks شكرا رجاء"),
        .init(name: "Share", emoji: "🤝", keywords: "share sharing together مشاركة"),
        .init(name: "Sit", emoji: "🪑", keywords: "sit chair seat كرسي اجلس"),
        .init(name: "Stand", emoji: "🧍", keywords: "stand standing قف وقوف"),
        .init(name: "Light", emoji: "💡", keywords: "light lamp bright مصباح ضوء"),
        .init(name: "Sun", emoji: "☀️", keywords: "sun sunshine sunny شمس"),
        .init(name: "Rain", emoji: "🌧️", keywords: "rain rainy wet مطر"),
        .init(name: "Moon", emoji: "🌙", keywords: "moon night evening قمر ليل"),
        .init(name: "Flower", emoji: "🌼", keywords: "flower flowers زهرة"),
        .init(name: "Talk", emoji: "💬", keywords: "talk speak words chat كلام"),
    ]

    private static let bundledPictures: [LibraryPicture] = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: "Pictures"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([LibraryPicture].self, from: data) else { return [] }
        return entries
    }()
    static let pictures = starterPictures + bundledPictures
    private static let byID = Dictionary(pictures.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    private struct IndexedPicture {
        let picture: LibraryPicture
        let name: [String]
        let tags: [String]
        let words: [String]
    }
    // Normalize once, not once per symbol on every keystroke.
    private static let index: [IndexedPicture] = pictures.map {
        let name = normalized($0.name), tags = normalized($0.keywords)
        return IndexedPicture(picture: $0, name: name, tags: tags, words: name + tags)
    }

    static func assetName(for symbol: String) -> String {
        "picture-" + symbol.unicodeScalars.map { String($0.value, radix: 16) }.joined(separator: "-")
    }
    static func picture(for symbol: String) -> LibraryPicture? {
        byID[symbol]
    }
    private static func normalized(_ text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    }
    private static let stopWords: Set<String> = ["i", "a", "an", "the", "want", "would", "like", "to", "some", "my", "me", "need", "is", "am", "it", "اريد", "انا"]

    static func search(_ query: String) -> [LibraryPicture] {
        let raw = normalized(query)
        if raw.isEmpty { return pictures }
        let tokens = raw.filter { !stopWords.contains($0) }
        guard !tokens.isEmpty else { return [] }
        let phrase = raw.joined(separator: " ")
        return index.enumerated().compactMap { position, entry -> (LibraryPicture, Int, Int)? in
            let item = entry.picture, name = entry.name, tags = entry.tags, words = entry.words
            guard tokens.allSatisfy({ token in words.contains { $0.hasPrefix(token) } }) else { return nil }
            let score = (name.joined(separator: " ") == phrase ? 1000 : 0)
                + tokens.reduce(0) { total, token in
                    total + (name.contains(token) ? 100 : tags.contains(token) ? 50 : 10)
                }
            return (item, score, position)
        }.sorted { $0.1 == $1.1 ? $0.2 < $1.2 : $0.1 > $1.1 }.map { $0.0 }
    }
}

@MainActor enum PictureImageStore {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 64
        cache.totalCostLimit = 24 * 1024 * 1024
        return cache
    }()
    static func image(for picture: LibraryPicture) -> UIImage? {
        if picture.sourceID == nil { return UIImage(named: picture.assetName) }
        let key = picture.id as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let url = Bundle.main.url(forResource: picture.id, withExtension: "png", subdirectory: "Pictures"),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: key, cost: 256 * 256 * 4)
        return image
    }
}
