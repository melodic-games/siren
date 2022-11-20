using System;
using System.Collections.Generic;
using Siren.Scripts.UI;
using UnityEngine;

public class TweenManager
{
    public abstract class Tweener
    {
        public virtual void Update()
        {
        }
    }

    public class Tweener<T> : Tweener
    {
        public T From;
        public T To;

        private float _startTime;
        private float _endTime;

        public T Current;
        public bool Finished = true;

        private EasingFunctions.Easing _easingFunction;
        private readonly Action<T> _transitionFunction;

        public Tweener(Action<T> transitionFunction, T initial)
        {
            _transitionFunction = transitionFunction;
            From = initial;
            To = initial;
            Current = initial;
            transitionFunction(initial);
        }

        public void Tween(T to, float ms, EasingFunctions.Easing easingFunction)
        {
            From = Current;
            To = to;

            _startTime = Time.realtimeSinceStartup;
            _endTime = Time.realtimeSinceStartup + ms / 1000;

            _easingFunction = easingFunction;
            Finished = false;
        }

        public override void Update()
        {
            if (Finished) return;

            if (Time.realtimeSinceStartup > _endTime)
            {
                _transitionFunction(To);
                Current = To;
                Finished = true;
                return;
            }

            var duration = _endTime - _startTime;

            var t = (Time.realtimeSinceStartup - _startTime) / duration;
            t = EasingFunctions.Ease(t, _easingFunction);
            
            // thanks you rider, i just hope this is optimized enough
            var n = From switch
            {
                float fromFloat when To is float toFloat =>
                    (T) Convert.ChangeType(Mathf.Lerp(fromFloat, toFloat, t), typeof(T)),
                Color fromColor when To is Color toColor =>
                    (T) Convert.ChangeType(Color.Lerp(fromColor, toColor, t), typeof(T)),
                Vector2 fromVector2 when To is Vector2 toVector2 =>
                    (T) Convert.ChangeType(Vector2.Lerp(fromVector2, toVector2, t), typeof(T)),
                Vector3 fromVector3 when To is Vector3 toVector3 =>
                    (T) Convert.ChangeType(Vector3.Lerp(fromVector3, toVector3, t), typeof(T)),
                Quaternion fromQuaternion when To is Quaternion toQuaternion =>
                    (T) Convert.ChangeType(Quaternion.Lerp(fromQuaternion, toQuaternion, t), typeof(T)),
                _ => default
            };

            _transitionFunction(n);
            Current = n;
        }
    }

    private readonly List<Tweener> _tweeners = new();

    public Tweener<T> NewTweener<T>(Action<T> transition, T initial)
    {
        var tweener = new Tweener<T>(transition, initial);
        _tweeners.Add(tweener);
        return tweener;
    }

    public void Update()
    {
        foreach (var tweener in _tweeners)
        {
            tweener.Update();
        }
    }
}