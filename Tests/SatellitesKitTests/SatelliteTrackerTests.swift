import Testing
@testable import SatellitesKit

struct SatelliteTrackerTests {
    @Test("USA-247 TLE parses successfully")
    func usa247TLEParsing() throws {
        let tracker = try SatelliteTracker(satellite: .usa247)
        #expect(tracker.trackedSatellite.noradID == 39462)
        #expect(tracker.trackedSatellite.name == "USA-247 (NROL-39)")
    }

    @Test("Orbital period is calculated correctly for USA-247")
    func orbitalPeriod() throws {
        let tracker = try SatelliteTracker(satellite: .usa247)
        // USA-247 has ~107 minute period (13.41 revs/day)
        let period = tracker.orbitalPeriodMinutes
        #expect(period > 100 && period < 120)
    }

    @Test("Inclination is calculated correctly for USA-247")
    func inclination() throws {
        let tracker = try SatelliteTracker(satellite: .usa247)
        // USA-247 has retrograde orbit ~123 degrees
        let inclination = tracker.inclination
        #expect(inclination > 120 && inclination < 130)
    }

    @Test("Position calculation returns valid coordinates")
    func positionCalculation() throws {
        let tracker = try SatelliteTracker(satellite: .usa247)
        let position = try tracker.geodeticPosition(at: Date())

        #expect(position.latitude >= -90 && position.latitude <= 90)
        #expect(position.longitude >= -180 && position.longitude <= 180)
        #expect(position.altitude > 1000 && position.altitude < 1500) // ~1100 km orbit
    }

    @Test("Topocentric position is calculated from observer")
    func topocentricPosition() throws {
        let tracker = try SatelliteTracker(satellite: .usa247)
        let topo = try tracker.topocentricPosition(at: Date(), from: .sanFrancisco)

        #expect(topo.azimuth >= 0 && topo.azimuth <= 360)
        #expect(topo.elevation >= -90 && topo.elevation <= 90)
        #expect(topo.range > 0)
    }

    @Test("Ground track generates multiple points")
    func groundTrack() throws {
        let tracker = try SatelliteTracker(satellite: .usa247)
        let track = try tracker.groundTrack(
            from: Date(),
            duration: 3600, // 1 hour
            interval: 60
        )

        #expect(track.count > 50) // Should have ~60 points for 1 hour at 60s intervals
    }
}
