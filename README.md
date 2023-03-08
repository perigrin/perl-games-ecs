# Games::ECS

A Simple ECS (Entity Component System) for Perl. This is based _heavily_ on [this Typescript](https://maxwellforbes.com/posts/typescript-ecs-tests/) ECS.

## Synopsis

```perl
use Feature::Compat::Class; # or perl 5.38.0
use Games::ECS;

class Position :isa(Games::ECS::Component) {
    field $x :param;
    field $y :param;

    method x { $x }
    method y { $y }

    method move($dx, $dy) {
        $x += $dx;
        $y += $dy;
    }
}

class Locator :isa(Games::ECS::System) {
    method components_required { ['Position'] }

    method update(@entities) {
        for (@entities) {
            my $p = $self->ecs->get_component($_)->get('Position');
            say "entity:$_ is at ${\$p->x},${\$p->y}";
        }
    }
}


my $ecs = Games::ECS->new();
my $e1 = $ecs->add_entity(); # make a new thing
my $p1 = Position->new(x => 0, y => 0); # new position, top left

$ecs->add_component($e1, $p1); # e1 now has a position, it's top left

my $locator = Locator->new();
$ecs->add_system($locator);
$ecs->update(); # "entity:0 is at 0,0"

# move e1 diagonally 1 square
$ecs->get_component($e1)->get('Position')->move(1,1);
$ecs->update(); # "entity:0 is at 1,1"
```


