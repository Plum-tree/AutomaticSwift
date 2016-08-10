import UIKit

private let reuseIdentifier = "vendingItem"
private let screenWidth = UIScreen.mainScreen().bounds.width

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //商品を並べるエリア
    @IBOutlet weak var collectionView: UICollectionView!
    // 合計の値段(払うお金）
    @IBOutlet weak var totalLabel: UILabel!
    // 所持金(持っているお金）
    @IBOutlet weak var balanceLabel: UILabel!
    // 商品の個数
    @IBOutlet weak var quantityLabel: UILabel!
    
    let vendingMachine: VendingMachineType
    
    //　VendingSelection(enum)のインスタンス
    var currentSelection: VendingSelection?
    var quantity: Double = 1.0
    
    required init?(coder aDecoder: NSCoder){
        do {
            //ここでvendingInventory.plistにアクセスしている
            let dictionary = try PlistConverter.dictionaryFromFile("VendingInventory", ofType: "plist")
            
            let inventory = try InventoryUnarchiver.vendingInventoryFromDictionary(dictionary)
            
            self.vendingMachine = VendingMachine(inventory: inventory)
        }catch let error {
            fatalError("\(error)")
        }
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViewCells()
        setUpViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpViews(){
        updateQuantityLabel()
        updateBalanceLabel()
    }

    // 初期画面のレイアウト
    func setupCollectionViewCells() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        let padding: CGFloat = 10
        layout.itemSize = CGSize(width: (screenWidth / 3) - padding, height: (screenWidth / 3) - padding)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    // 商品が何個あるかを返すメソッド
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vendingMachine.selection.count
    }

    //
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VendingItemCell
        
        // ここでアイテムの順番を取得
        let item = vendingMachine.selection[indexPath.row]
        // アイコンをcell定数に入れる
        cell.iconView.image = item.icon()
        
        return cell
    }
    
    // 選択したときに動くメソッド
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        updateCellBackgroundColor(indexPath, selected: true)
        reset()
        currentSelection = vendingMachine.selection[indexPath.row]
        updateTotalPriceLabel()
    }
    
    // 選択されなかったときに動くメソッド
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        updateCellBackgroundColor(indexPath, selected: false)
    }
    
    
    // 背景色を変えるメソッド
    func updateCellBackgroundColor(indexPath: NSIndexPath, selected: Bool) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
            cell.contentView.backgroundColor = selected ? UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0) : UIColor.clearColor()
        }
    }

    // Purchaseボタンが押された時に動くメソッド
    @IBAction func Purchase() {
        if let currentSelection = currentSelection {
            do{
                try vendingMachine.vend(currentSelection, quantity: quantity)
                updateBalanceLabel()
            }catch VendingMachineError.OutOfStock{
                //　商品切れのアラート
                showAlert("Out of Stock")
            }catch VendingMachineError.InvalidSelection{
                showAlert("Invalid Selection")
            }catch VendingMachineError.InsufficientFunds(let amount){
                showAlert("Insufficient Funds", message: "Additional $\(amount) needed to complete the transacation")
            }catch let error{
                fatalError("\(error)")
            }
        } else{
            
        }
    }
    
    
    @IBAction func UpdateQuantity(sender: UIStepper) {
        quantity = sender.value
        updateTotalPriceLabel()
        updateQuantityLabel()
    }
    
    
    // Label更新メソッドシリーズ
    
    // 個数の更新
    func updateQuantityLabel(){
        quantityLabel.text = "\(quantity)"
    }
    
    // 所持金の更新
    func updateBalanceLabel(){
        balanceLabel.text = "$\(vendingMachine.amountDeposited)"
    }
    
    //　合計金の更新
    func updateTotalPriceLabel(){
        // この黄緑のcurrentSelectionはVendingMachine?のインスタンス
        // 最初のlet文はunwrappingしている(黄緑のcurrentSelectionはoptional型であるため、空のものじゃないか確認している）
        if let currentSelection = currentSelection,
            let item = vendingMachine.itemForCurrentSelection(currentSelection){
                totalLabel.text = "$\(item.price * quantity)"
        }
    }
    
    func reset(){
        quantity = 1
        updateQuantityLabel()
        updateTotalPriceLabel()
    }
    
    // エラーアラートを出すメソッド
    func showAlert(title: String, message: String? = nil, style: UIAlertControllerStyle = .Alert){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: dismissAlert)
        alertController.addAction(okAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func dismissAlert(sender: UIAlertAction){
        reset()
    }
    
    @IBAction func depositFunds() {
        vendingMachine.deposit(5.00)
        updateBalanceLabel()
    }
    
    /*
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
    updateCellBackgroundColor(indexPath, selected: true)
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
    updateCellBackgroundColor(indexPath, selected: false)
    }
    
    */
    
}








