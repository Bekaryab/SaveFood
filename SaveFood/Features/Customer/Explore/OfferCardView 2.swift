//
//  OfferCardView 2.swift
//  SaveFood
//
//  Created by bekarys abiev on 15.11.2026.
//


import SwiftUI

struct OfferCardView: View {

    let offer: HomeProductOffer
    var onToggleFavorite: () -> Void

    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    private let badgeGreen = Color(red: 0.22, green: 0.49, blue: 0.18)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Жоғарғы жеңілдік (-40%) және таңдаулы жүрекшесі
            HStack {
                Text("-\(offer.discountPercent)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(badgeGreen)
                    )

                Spacer()

                Button(action: onToggleFavorite) {
                    Image(systemName: offer.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(offer.isFavorite ? Color.red : primaryGreen)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Тауар суреті (Алдымен өз суретіңізді тексереді, одан соң URL)
            Group {
                if SmartLocalImage.hasImage(named: offer.localImageName) {
                    SmartLocalImage(imageName: offer.localImageName)
                        .scaledToFill()
                        .frame(height: 110)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 10)
                } else {
                    AsyncImage(url: URL(string: offer.imageURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 110)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(.horizontal, 10)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(offer.accentColor.opacity(0.14))

                                Image(systemName: "cart.fill")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(offer.accentColor)
                            }
                            .frame(height: 110)
                            .padding(.horizontal, 10)
                        }
                    }
                }
            }
            .padding(.vertical, 8)

            // Мекеме аты, тауар аты және бағасы
            VStack(alignment: .leading, spacing: 3) {
                Text(offer.venueName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.42, green: 0.49, blue: 0.43))
                    .lineLimit(1)

                Text(offer.title)
                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryGreen)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(offer.currentPrice)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(primaryGreen)

                    Text(offer.oldPrice)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(red: 0.50, green: 0.54, blue: 0.49))
                        .strikethrough(true, color: Color(red: 0.50, green: 0.54, blue: 0.49))
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.938, green: 0.953, blue: 0.910))
        )
    }
}