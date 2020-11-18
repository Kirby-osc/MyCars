//
//  ViewController.swift
//  MyCars
//
//  Created by Ivan Akulov on 07/11/16.
//  Copyright © 2016 Ivan Akulov. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var selectedCar: Car?
    
    lazy var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    
    fileprivate func insertDataFrom(selectedCar:Car) {
        markLabel.text = selectedCar.mark
        modelLabel.text = selectedCar.model
        carImageView.image = UIImage(data: selectedCar.imageData!)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        lastTimeStartedLabel.text = "Last time started: \(dateFormatter.string(from: selectedCar.lastStarted!))"
        
        numberOfTripsLabel.text = selectedCar.timesDriven?.stringValue
        ratingLabel.text = selectedCar.rating?.stringValue
        myChoiceImageView.isHidden = !(selectedCar.myChoice?.boolValue)!
        
        segmentedControl.backgroundColor = (selectedCar.tintColor as! UIColor)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDataFromFile()
        
        let mark = segmentedControl.titleForSegment(at: 0)
        let fetchRequest:NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate.init(format: "mark == %@", mark!) // %@ - обозначает расположение переменной любого типа
        
        do {
            let results = try context.fetch(fetchRequest)
            selectedCar = results[0]
        } catch  {
            print(error.localizedDescription)
        }
        insertDataFrom(selectedCar: selectedCar!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getDataFromFile(){
        //Формируем запрос
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        //Формируем фильтр для запроса
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        
        do {
            let count = try context.count(for: fetchRequest)
            records = count
        } catch {
            print(error.localizedDescription)
        }
        
        guard records == 0 else {
            return
        }
        //Инициализируем переменную со значением местоположения файла в корневой директории проекта
        // - forResource: название файла
        // - ofType: разрешение файла
        let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist")
        
        
        //Извлекаем массив по указанному пути
        let dataArray = NSArray(contentsOfFile: pathToFile!)!
        
        for dictionary in dataArray{
            let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)
            let car = NSManagedObject(entity: entity!, insertInto: context) as! Car
            let carDictionary = dictionary as! NSDictionary
            
            car.model = carDictionary["model"] as? String
            car.mark = carDictionary["mark"] as? String
            car.timesDriven = carDictionary["timesDriven"] as? NSNumber
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.rating = carDictionary["rating"] as? NSNumber
            car.myChoice = carDictionary["myChoice"] as? NSNumber
            
            let imageName = carDictionary["imageName"] as? String
            let image = UIImage(named: imageName!)
            let imageData = image?.pngData()
            car.imageData = imageData
            
            let tintColorDict = carDictionary["tintColor"] as? NSDictionary
            car.tintColor = getColor(colorDict: tintColorDict!)
        }
        
    }
    
    func getColor(colorDict: NSDictionary)->UIColor{
        let red = colorDict["red"] as! NSNumber
        let green = colorDict["green"] as! NSNumber
        let blue = colorDict["blue"] as! NSNumber
        
        return UIColor(red: CGFloat(red.floatValue)/255, green: CGFloat(green.floatValue)/255, blue: CGFloat(blue.floatValue)/255, alpha: 1.0)
    }
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        let mark = sender.titleForSegment(at: sender.selectedSegmentIndex)
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark!)
        
        do {
            let result = try context.fetch(fetchRequest)
            selectedCar = result[0]
            insertDataFrom(selectedCar: selectedCar!)
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        
        let timesCounter = selectedCar?.timesDriven
        selectedCar?.timesDriven = NSNumber(value: timesCounter!.intValue + 1)
        selectedCar?.lastStarted = NSDate() as Date
        
        do {
            try context.save()
            insertDataFrom(selectedCar: selectedCar!)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    @IBAction func MyChoicePressed(_ sender: Any) {
        let choice = !(selectedCar?.myChoice?.boolValue)!
        selectedCar?.myChoice = choice as NSNumber
        do {
            try context.save()
            insertDataFrom(selectedCar: selectedCar!)
        } catch  {
            print(error.localizedDescription)
        }
    }
    @IBAction func rateItPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Rate", message: "Please, rate this car.", preferredStyle: .alert)
        
        alertController.addTextField(){
            textField in
            textField.keyboardType = .numberPad
        }
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in
            let rating = alertController.textFields?[0].text
            self.update(rating: rating!)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    func update(rating:String){
        let doubleRating = Double(rating)
        selectedCar?.rating = NSNumber(value: doubleRating!)
        do {
            try context.save()
            insertDataFrom(selectedCar: selectedCar!)
        } catch {
            let alertController = UIAlertController(title: "Wrong rating", message: "Entered rating is incorrect", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            print(error.localizedDescription)
        }
    }
}

