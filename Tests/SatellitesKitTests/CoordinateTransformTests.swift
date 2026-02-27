import Testing
@testable import SatellitesKit

struct CoordinateTransformTests {
    @Test("GMST calculation returns valid range")
    func gmstRange() {
        let gmst = CoordinateTransform.greenwichMeanSiderealTime(Date())
        #expect(gmst >= 0 && gmst < 2 * .pi)
    }

    @Test("ECI to geodetic conversion produces valid latitude")
    func eciToGeodeticLatitude() {
        let eci = ECIPosition(x: 6878.0, y: 0.0, z: 0.0, date: Date())
        let geodetic = CoordinateTransform.eciToGeodetic(eci, at: Date())

        #expect(geodetic.latitude >= -90 && geodetic.latitude <= 90)
    }

    @Test("ECI to geodetic conversion produces valid longitude")
    func eciToGeodeticLongitude() {
        let eci = ECIPosition(x: 6878.0, y: 0.0, z: 0.0, date: Date())
        let geodetic = CoordinateTransform.eciToGeodetic(eci, at: Date())

        #expect(geodetic.longitude >= -180 && geodetic.longitude <= 180)
    }

    @Test("ECI to topocentric produces valid azimuth")
    func topocentricAzimuth() {
        let eci = ECIPosition(x: 7000.0, y: 1000.0, z: 1000.0, date: Date())
        let topo = CoordinateTransform.eciToTopocentric(
            eci,
            observer: .sanFrancisco,
            at: Date()
        )

        #expect(topo.azimuth >= 0 && topo.azimuth <= 360)
    }

    @Test("ECI to topocentric produces valid elevation")
    func topocentricElevation() {
        let eci = ECIPosition(x: 7000.0, y: 1000.0, z: 1000.0, date: Date())
        let topo = CoordinateTransform.eciToTopocentric(
            eci,
            observer: .sanFrancisco,
            at: Date()
        )

        #expect(topo.elevation >= -90 && topo.elevation <= 90)
    }
}
