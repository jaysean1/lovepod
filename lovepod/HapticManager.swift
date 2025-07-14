// lovepod/HapticManager.swift
// 触觉反馈管理器，提供不同强度的震动反馈
// 用于增强iPod转盘操作的触觉体验

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        // 准备生成器以减少延迟
        prepareGenerators()
    }
    
    // MARK: - Public Methods
    
    /// 轻微震动 - 用于转盘旋转时的反馈
    func lightImpact() {
        lightGenerator.impactOccurred()
    }
    
    /// 中等震动 - 用于菜单项切换
    func mediumImpact() {
        mediumGenerator.impactOccurred()
    }
    
    /// 强烈震动 - 用于重要操作确认
    func heavyImpact() {
        heavyGenerator.impactOccurred()
    }
    
    /// 选择反馈 - 用于菜单项选择
    func selectionChanged() {
        selectionGenerator.selectionChanged()
    }
    
    /// 成功反馈 - 用于操作成功
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// 错误反馈 - 用于操作失败
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// 警告反馈 - 用于警告提示
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    // MARK: - iPod Specific Feedback
    
    /// 转盘旋转反馈 - 轻微震动
    func wheelRotation() {
        lightImpact()
    }
    
    /// 菜单项切换反馈 - 选择震动
    func menuItemChanged() {
        selectionChanged()
    }
    
    /// 按钮点击反馈 - 中等震动
    func buttonTap() {
        mediumImpact()
    }
    
    /// 页面切换反馈 - 中等震动
    func pageTransition() {
        mediumImpact()
    }
    
    /// 播放状态切换反馈 - 强烈震动
    func playbackToggle() {
        heavyImpact()
    }
    
    /// 音量调节反馈 - 轻微震动
    func volumeAdjustment() {
        lightImpact()
    }
    
    /// 进度调节反馈 - 轻微震动
    func progressScrubbing() {
        lightImpact()
    }
    
    // MARK: - Private Methods
    
    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    /// 检查设备是否支持触觉反馈
    var isHapticsAvailable: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}