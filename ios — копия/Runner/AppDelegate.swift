import Flutter
import UIKit
import AuthenticationServices
import SuperwallKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Инициализация Superwall
    Superwall.configure(apiKey: "pk_a8d000b9824387f66332c9958e30bfad0e9b22ec844b52fc")
    
    // Настраиваем канал связи между Flutter и iOS
    let controller = window?.rootViewController as! FlutterViewController
    let superwallChannel = FlutterMethodChannel(name: "com.fitbod.superwall",
                                              binaryMessenger: controller.binaryMessenger)
    
    // Обработчик методов из Flutter
    superwallChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      if call.method == "showPaywall" {
        // Получаем ID пейвола из аргументов
        let paywallIdentifier = call.arguments as? String ?? "default"
        
        // Показываем пейвол
        Superwall.shared.register(event: paywallIdentifier)
        result(true)
      } 
      else if call.method == "isSubscribed" {
        // Проверяем, подписан ли пользователь
        let isSubscribed = Superwall.shared.isUserSubscribed()
        result(isSubscribed)
      }
      else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Обрабатываем URL схемы для авторизации
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Позволяем плагинам обрабатывать URL
    return super.application(app, open: url, options: options)
  }
}
