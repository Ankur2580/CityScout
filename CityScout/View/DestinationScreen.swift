//
//  DestinationScreen.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import SwiftUI

struct DestinationScreen: View {
    @StateObject private var viewModel: DestinationViewModel

    init(viewModel: DestinationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: UIValues.Destination.stackSpacing) {
                    headerView

                    switch viewModel.state {
                    case .loading:
                        ProgressView()
                            .tint(AppColors.textPrimary)
                            .padding(.top, UIValues.Destination.loadingTopPadding)

                    case let .success(activities):
                        ForEach(activities) { item in
                            activityCard(item)
                        }

                    case let .failed(message):
                        cardContainer {
                            VStack(alignment: .leading, spacing: UIValues.Destination.errorSpacing) {
                                Text(message)
                                    .foregroundStyle(AppColors.textPrimary)
                                    .font(.system(size: UIValues.Destination.errorTextSize, weight: .semibold, design: .rounded))

                                Button(UIStrings.Destination.retryButton) {
                                    viewModel.retry()
                                }
                                .font(.system(size: UIValues.Destination.retryTextSize, weight: .bold, design: .rounded))
                                .padding(.horizontal, UIValues.Destination.retryHorizontalPadding)
                                .padding(.vertical, UIValues.Destination.retryVerticalPadding)
                                .background(Capsule().fill(AppColors.textPrimary))
                                .foregroundStyle(AppColors.buttonTextDark)
                            }
                        }
                    }
                }
                .padding(UIValues.Destination.contentPadding)
                .padding(.bottom, UIValues.Destination.bottomPadding)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.city.name)
                    .font(.system(size: UIValues.Search.toolbarTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            viewModel.fetchRanking()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var background: some View {
        ZStack {
            AppColors.deepNavy
                .ignoresSafeArea()

            LinearGradient(
                colors: [AppColors.oceanTop, AppColors.oceanMid, AppColors.oceanBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var headerView: some View {
        VStack(spacing: UIValues.Destination.headerSpacing) {
            Text(UIStrings.Destination.analysisTitle)
                .font(.system(size: UIValues.Destination.headerTitleSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(UIStrings.Destination.analysisSubtitle(city: viewModel.city))
                .font(.system(size: UIValues.Destination.headerSubtitleSize, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func cardContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UIValues.Destination.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: UIValues.Destination.cardCornerRadius, style: .continuous)
                    .fill(AppColors.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIValues.Destination.cardCornerRadius, style: .continuous)
                    .stroke(AppColors.cardStroke, lineWidth: UIValues.Destination.cardStroke)
            )
    }

    private func activityCard(_ item: ActivityScore) -> some View {
        VStack(alignment: .leading, spacing: UIValues.Destination.headerSpacing + 2) {
            HStack {
                Label(item.activity.title, systemImage: item.activity.symbolName)
                    .font(.system(size: UIValues.Destination.activityHeaderSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text("\(item.score)")
                    .font(.system(size: UIValues.Destination.activityHeaderSize, weight: .black, design: .rounded))
                    .foregroundStyle(item.activity.accentColor)
                    .padding(.horizontal, UIValues.Destination.scoreHorizontalPadding)
                    .padding(.vertical, UIValues.Destination.scoreVerticalPadding)
                        .background(Capsule().fill(AppColors.textPrimary))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.progressTrack).frame(height: UIValues.Destination.progressHeight)
                    Capsule()
                        .fill(item.activity.accentColor)
                        .frame(width: max(UIValues.Destination.progressMinWidth, proxy.size.width * CGFloat(item.score) / 100.0), height: UIValues.Destination.progressHeight)
                }
            }
            .frame(height: UIValues.Destination.progressHeight)

            Text(item.reason)
                .font(.system(size: UIValues.Destination.activityReasonSize, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(UIValues.Destination.activityCardPadding)
        .background(
            RoundedRectangle(cornerRadius: UIValues.Destination.activityCardCornerRadius, style: .continuous)
                .fill(AppColors.rowFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIValues.Destination.activityCardCornerRadius, style: .continuous)
                .stroke(AppColors.cardStroke, lineWidth: UIValues.Destination.cardStroke)
        )
    }
}

#Preview {
    DestinationScreen(viewModel: AppSetupBuilder.makePreviewDestinationViewModel(for: City(name: "Tokyo", country: "Japan", latitude: 35.67, longitude: 139.65)))
}
