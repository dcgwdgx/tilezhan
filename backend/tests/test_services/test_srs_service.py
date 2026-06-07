"""SRS SM-2 algorithm tests."""

from app.domain.services.srs_service import SrsService


class TestSM2Algorithm:
    def setup_method(self):
        self.service = SrsService()

    def test_perfect_recall_increases_interval(self):
        """quality=5 should increase interval"""
        result = self.service._sm2(ef=2.5, reps=0, interval=1, quality=5)
        ef, reps, interval = result
        assert ef >= 2.5
        assert reps == 1
        assert interval >= 1

    def test_forget_resets(self):
        """quality=0 should reset to day 1"""
        result = self.service._sm2(ef=2.6, reps=3, interval=15, quality=0)
        ef, reps, interval = result
        assert reps == 0
        assert interval == 1

    def test_ef_never_below_1_3(self):
        """Easiness factor floor is 1.3"""
        result = self.service._sm2(ef=1.3, reps=0, interval=1, quality=1)
        ef, _, _ = result
        assert ef >= 1.3

    def test_interval_progression(self):
        """Simulate a card being reviewed 5 times with perfect recall"""
        ef, reps, interval = 2.5, 0, 1
        for i in range(5):
            ef, reps, interval = self.service._sm2(ef, reps, interval, quality=5)
        assert interval > 30  # After 5 perfect reviews, interval should be >30 days

    def test_quality_3_barely_passes(self):
        """quality=3 (correct but difficult) should still advance"""
        result = self.service._sm2(ef=2.5, reps=0, interval=1, quality=3)
        ef, reps, interval = result
        assert reps >= 1
        assert interval >= 1
